// Se tiene que llamar reg_control.sv
// Registro de Control del periférico UART (SystemVerilog)
// Propósito:
//  - Exponer un registro de control de 32 bits (reg_sel = 0) accesible por el
//    agente externo vía bus de 32 bits (WR/RD).
//  - Reflejar estados y contadores de las FIFOs (Bytes TX/RX de 9 bits).
//  - Exponer bits auto-limpiables: enviar (send) y leer (read).
//  - Atender órdenes del bus S/C/DC (prioridad sobre WR externo).
// Contratos/responsabilidades:
//  - o_send_req / o_read_req pueden ser solicitados por el agente externo (WR)
//    o por S/C/DC; la Unidad de Control debe limpiar dichos bits mediante
//    i_scdc_clear_send / i_scdc_clear_read cuando complete la operación.
//  - Los campos Bytes TX/RX, FTXF y RXAV son Read-Only desde el agente externo.
//  - El empaquetado de lectura del registro de control respeta el mapa de bits
//    parametrizable definido abajo.
// ________________________________________________________________________________________

module reg_control #(
  parameter int WIDTH = 32,                  // ancho del bus externo
  parameter int CNT_WIDTH = 9,               // ancho de los contadores Bytes (9 bits)
  // Mapa de bits (parámetros para evitar "números mágicos")
  parameter int BIT_SEND   = 0,              // bit enviar (RW)
  parameter int BIT_READ   = 1,              // bit leer (RW)
  parameter int RX_L       = 2,              // inicio Bytes RX (inclusive)
  parameter int RX_H       = 10,             // fin Bytes RX (inclusive)
  parameter int TX_L       = 11,             // inicio Bytes TX
  parameter int TX_H       = 19,             // fin Bytes TX
  parameter int BIT_FTXF   = 20,             // FIFO TX full (RO)
  parameter int BIT_RXAV   = 21              // RX available (RO)
) (
  // Señales de reloj / reset
  input  logic                    i_clk,              // reloj principal
  input  logic                    i_rst_n,            // reset activo bajo

  // Interfaz bus externo (agente 32-bit)
  input  logic                    i_reg_sel,          // 0 -> control, 1 -> data
  input  logic                    i_wr,               // strobe de escritura
  input  logic                    i_rd,               // strobe de lectura
  input  logic [WIDTH-1:0]        i_reg_wr_data,      // datos de escritura (desde agente)
  output logic [WIDTH-1:0]        o_reg_rd_data,      // datos de lectura (hacia agente)

  // Señales provenientes de las FIFOs / Unidad de Control
  input  logic [CNT_WIDTH-1:0]    i_fifo_tx_count,    // nivel actual FIFO TX
  input  logic [CNT_WIDTH-1:0]    i_fifo_rx_count,    // nivel actual FIFO RX
  input  logic                    i_fifo_tx_full,     // indicador FIFO TX llena
  input  logic                    i_fifo_rx_not_empty, // indicador FIFO RX no vacía

  // Bus S/C/DC (control interno) - prioridad sobre WR externo
  input  logic                    i_scdc_set_send,    // solicitar enviar (set)
  input  logic                    i_scdc_clear_send,  // clear enviar (auto-clear por UC)
  input  logic                    i_scdc_set_read,    // solicitar leer (set)
  input  logic                    i_scdc_clear_read,  // clear leer (auto-clear por UC)

  // Salidas hacia Unidad de Control / módulo datos
  output logic                    o_send_req,         // petición de iniciar envío (enviar)
  output logic                    o_read_req,         // petición para extraer 1 byte de RX
  output logic [CNT_WIDTH-1:0]    o_bytes_tx,         // reflejo fifo_tx_count
  output logic [CNT_WIDTH-1:0]    o_bytes_rx,         // reflejo fifo_rx_count
  output logic                    o_ftxf,             // indicador FIFO TX full (RO)
  output logic                    o_rxav              // indicador FIFO RX has data (RO)
);

  // ________________________________________________________________________________________
  // Registros internos - r_ prefix para registros (estado)
  // ________________________________________________________________________________________
  logic r_send_req;    // registro que mantiene solicitud de enviar (auto-clear por UC)
  logic r_read_req;    // registro que mantiene solicitud de leer (auto-clear por UC)

  // ________________________________________________________________________________________
  // Lógica sincrónica principal
  // - Actualiza contadores/flags desde las señales FIFO cada ciclo
  // - Atiende S/C/DC (prioridad) antes que WR externo
  // - Escritura externa sólo modifica bits writeable (send, read)
  // ________________________________________________________________________________________
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_send_req <= 1'b0;
      r_read_req <= 1'b0;
      o_bytes_tx <= '0;
      o_bytes_rx <= '0;
      o_ftxf     <= 1'b0;
      o_rxav     <= 1'b0;
      o_reg_rd_data <= '0;
    end else begin
      // Reflejar conteos y flags desde las FIFOs
      o_bytes_tx <= i_fifo_tx_count;
      o_bytes_rx <= i_fifo_rx_count;
      o_ftxf     <= i_fifo_tx_full;
      o_rxav     <= i_fifo_rx_not_empty;

      // Prioridad S/C/DC: procesar comandos internos primero
      if (i_scdc_set_send)   r_send_req <= 1'b1;
      if (i_scdc_clear_send) r_send_req <= 1'b0;

      if (i_scdc_set_read) begin
        // Solicitar leer sólo si hay dato en FIFO RX
        if (i_fifo_rx_not_empty) r_read_req <= 1'b1;
      end
      if (i_scdc_clear_read) r_read_req <= 1'b0;

      // Escritura externa (solo cuando i_reg_sel == 0)
      if ((i_reg_sel == 1'b0) && i_wr) begin
        // El agente externo puede poner los bits SEND y READ.
        // S/C/DC ya fue procesado (prioridad).
        r_send_req <= i_reg_wr_data[BIT_SEND];
        if (i_reg_wr_data[BIT_READ] && i_fifo_rx_not_empty)
          r_read_req <= 1'b1;
      end
    end
  end

  // asignaciones de salida conectadas a registros internos
  assign o_send_req = r_send_req;
  assign o_read_req = r_read_req;

  // ________________________________________________________________________________________
  // Lógica combinacional de lectura del registro de control
  // - Si se hace RD y reg_sel == 0, empaqueta todos los campos en 32 bits
  // - Los campos write-only o RO se respetan según mapa
  // ________________________________________________________________________________________
  always_comb begin
    // por defecto devolvemos 0 cuando no es lectura de control
    o_reg_rd_data = '0;
    if ((i_reg_sel == 1'b0) && i_rd) begin
      // Empaquetado conforme mapa de bits parametrizable
      o_reg_rd_data = '0;
      o_reg_rd_data[BIT_SEND] = r_send_req;
      o_reg_rd_data[BIT_READ] = r_read_req;
      // Bytes RX en el rango RX_H:RX_L
      o_reg_rd_data[RX_H:RX_L] = o_bytes_rx;
      // Bytes TX en el rango TX_H:TX_L
      o_reg_rd_data[TX_H:TX_L] = o_bytes_tx;
      o_reg_rd_data[BIT_FTXF] = o_ftxf;
      o_reg_rd_data[BIT_RXAV] = o_rxav;
      // Los bits restantes quedan en 0 (reservados)
    end
  end

endmodule
