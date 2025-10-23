// Se le tiene que llamar reg_data.sv
// Registro de Datos del periférico UART
// Propósito:
//  - Manejar accesos de 32 bits del agente externo (reg_sel = 1) y convertirlos en hasta cuatro pushes de 8 bits hacia la FIFO TX.
//  - Mantener un buffer de lectura para un byte extraído desde FIFO RX y presentar ese byte en la lectura externa (campo [7:0] del reg_data).
//  - Generar las señales fifo_tx_push_en / fifo_tx_push_data y fifo_rx_pop_en para que los módulos FIFO y/o la Unidad de Control ejecuten las operaciones.
// Reglas importantes:
//  - Endianness definido: i_reg_wr_data[7:0] => primer byte enviado a FIFO (LSB primer). i_reg_wr_data[31:24] => cuarto byte (MSB último). Documentado y consistente.
//  - Cuando se intenta escribir más bytes que espacio disponible en FIFO TX, sólo se empujan los bytes que quepan y se reporta cuántos mediante
//    o_last_write_count (útil para testbench). El reg_control actualiza bytes_tx.
//  - Para la lectura: la Unidad de Control debe setear i_read_consume_done para indicar que el byte colocado en buffer de lectura fue consumido por el agente.
// ___________________________________________________________________________________________________

module reg_data #(
  parameter int WIDTH = 32,
  parameter int CNT_WIDTH = 9
) (
  // Reloj / reset
  input  logic                 i_clk,
  input  logic                 i_rst_n,

  // Bus externo (agente)
  input  logic                 i_reg_sel,            // 0 control, 1 data
  input  logic                 i_wr,
  input  logic                 i_rd,
  input  logic [WIDTH-1:0]     i_reg_wr_data,
  output logic [WIDTH-1:0]     o_reg_rd_data,

  // Interface hacia FIFO TX (salida)
  output logic                 o_fifo_tx_push_en,    // pulso para insertar un byte
  output logic [7:0]          o_fifo_tx_push_data,     // byte a insertar en FIFO TX
  input  logic [CNT_WIDTH-1:0] i_fifo_tx_count,      // nivel actual FIFO TX
  input  logic                 i_fifo_tx_full,         // indicador FIFO TX lleno

  // Interface hacia FIFO RX (entrada)
  input  logic [7:0]           i_fifo_rx_data,         // dato leído desde FIFO RX (cuando pop realizado)
  input  logic                 i_fifo_rx_valid,      // indica i_fifo_rx_data válido (Unidad de Control hace pop)
  output logic                 o_fifo_rx_pop_en,      // solicitar pop (la Unidad de Control puede consumirlo)

  // Señales de control / estado auxiliares
  output logic [2:0]           o_last_write_count,   // cuántos bytes se escribieron en la última WR (0..4)
  // Señal que indica que el byte de lectura fue consumido por el agente (para limpiar buffer)
  input  logic                 i_read_consume_done
);

  // Estados para la secuencia de escritura
  typedef enum logic [1:0] {S_IDLE, S_WRITE_BYTES, S_WAIT_DONE} write_state_t;
  write_state_t s_write_state;

  // Registritos internos
  logic [1:0] r_write_byte_idx;        // índice 0..3 del siguiente byte a enviar
  logic [1:0] r_write_total_bytes;   // cuántos bytes solicitó el agente (1..4), almacenado temporalmente
  logic       r_pending_write;         // indica que hay una secuencia de push en curso
  logic [7:0] r_wr_bytes [0:3];      // bytes desempaquetados desde i_reg_wr_data (LSB primero)
  logic [1:0] r_bytes_written;          // cuántos bytes se han empujado efectivamente en la secuencia

  // Buffer de lectura RX (un solo byte)
  logic [7:0] r_buf_rx_byte;
  logic       r_buf_rx_valid;        // indica que r_buf_rx_byte contiene dato listo para lectura por agente

  // salida por defecto
  assign o_fifo_tx_push_en = (s_write_state == S_WRITE_BYTES) && (!i_fifo_tx_full);
  assign o_fifo_tx_push_data = r_wr_bytes[r_write_byte_idx];

  // o_fifo_rx_pop_en lo genera este módulo cuando se quiera solicitar pop
  // en este diseño el módulo expone la salida y la Unidad de Control decide cuando hacer pop.
  // Aquí dejamos la señal en 0 por defecto; la UC puede conectarla con o_read_req del reg_control.
  assign o_fifo_rx_pop_en = 1'b0;

  // ___________________________________________________________________________________________________
  // Desempaquetado de i_reg_wr_data en bytes (LSB primer)
  // r_wr_bytes[0] <= i_reg_wr_data[7:0]
  // r_wr_bytes[1] <= i_reg_wr_data[15:8]
  // r_wr_bytes[2] <= i_reg_wr_data[23:16]
  // r_wr_bytes[3] <= i_reg_wr_data[31:24]
  // ___________________________________________________________________________________________________

  always_comb begin
    r_wr_bytes[0] = i_reg_wr_data[7:0];
    r_wr_bytes[1] = i_reg_wr_data[15:8];
    r_wr_bytes[2] = i_reg_wr_data[23:16];
    r_wr_bytes[3] = i_reg_wr_data[31:24];
  end

  // ___________________________________________________________________________________________________
  // Secuencia de soporte para escritura 32->n×8
  // - Al detectar i_wr && i_reg_sel==1 iniciamos la secuencia.
  // - Determinamos cuántos bytes "validos" se desean escribir según un criterio
  //   simple: si los bytes de MSB son 0, podríamos ahorrar pushes, pero para
  //   simplicidad y cumplimiento de la especificación, asumimos que el agente
  //   quiere escribir 4 bytes siempre. Si se desea otra política, modificar.
  // - Verificamos i_fifo_tx_full antes de cada push; si está llena, detenemos la secuencia.
  // - o_last_write_count indica cuantos bytes fueron efectivamente empujados.
  // ___________________________________________________________________________________________________
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      s_write_state <= S_IDLE;
      r_write_byte_idx <= 2'd0;
      r_write_total_bytes <= 2'd0;
      r_pending_write <= 1'b0;
      r_bytes_written <= 2'd0;
      o_last_write_count <= 3'd0;
    end else begin
      case (s_write_state)
        S_IDLE: begin
          o_last_write_count <= 3'd0;
          r_bytes_written <= 2'd0;
          r_write_byte_idx <= 2'd0;
          r_write_total_bytes <= 2'd0;
          if ((i_reg_sel == 1'b1) && i_wr) begin
            // Inicio de una nueva escritura por parte del agente
            // Política: intentar escribir hasta 4 bytes en orden LSB->MSB.
            r_write_total_bytes <= 2'd4; // escribir 4 bytes por defecto
            r_pending_write <= 1'b1;
            s_write_state <= S_WRITE_BYTES;
          end
        end

        S_WRITE_BYTES: begin
          // Mientras tengamos bytes por enviar y FIFO no esté llena, generamos push
          if (r_write_byte_idx < r_write_total_bytes) begin
            if (!i_fifo_tx_full) begin
              // Generar push en esta ciclo: o_fifo_tx_push_en se activa por assign
              r_bytes_written <= r_bytes_written + 1;
              r_write_byte_idx <= r_write_byte_idx + 1;
            end else begin
              // FIFO llena: terminar secuencia y reportar cuantos se escribieron
              o_last_write_count <= r_bytes_written;
              r_pending_write <= 1'b0;
              s_write_state <= S_WAIT_DONE;
            end
          end else begin
            // todos los bytes solicitados fueron enviados
            o_last_write_count <= r_bytes_written;
            r_pending_write <= 1'b0;
            s_write_state <= S_WAIT_DONE;
          end
        end

        S_WAIT_DONE: begin
          // Esperamos un ciclo para estabilizar señales y volver al IDLE
          s_write_state <= S_IDLE;
        end

        default: s_write_state <= S_IDLE;
      endcase
    end
  end

  // ___________________________________________________________________________________________________

  // Gestión del buffer de lectura RX
  // - Cuando la Unidad de Control hace pop en la FIFO RX y presenta i_fifo_rx_valid=1
  //   con un byte en i_fifo_rx_data, se almacena en r_buf_rx_byte y r_buf_rx_valid=1.
  // - El agente externo lee con reg_sel=1 & i_rd; en la lectura se presenta el dato
  //   en o_reg_rd_data[7:0]. Cuando el agente confirma consumo (i_read_consume_done=1),
  //   se limpia r_buf_rx_valid.
  // ___________________________________________________________________________________________________

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_buf_rx_valid <= 1'b0;
      r_buf_rx_byte  <= 8'd0;
    end else begin
      // captura el byte proveniente de FIFO RX cuando la UC ya hizo pop y valida
      if (i_fifo_rx_valid) begin
        r_buf_rx_byte  <= i_fifo_rx_data;
        r_buf_rx_valid <= 1'b1;
      end

      // si el agente indica que consumió el dato, limpiar el buffer
      if (i_read_consume_done) begin
        r_buf_rx_valid <= 1'b0;
      end
    end
  end

  // ___________________________________________________________________________________________________

  // Respuesta de lectura externa (reg_sel=1 & i_rd)
  // - Si hay un byte en r_buf_rx_valid se presenta en [7:0]; el resto de bits quedan 0.
  // - Si no hay dato, se devuelve 0.
  // ___________________________________________________________________________________________________

  always_comb begin
    o_reg_rd_data = '0;
    if ((i_reg_sel == 1'b1) && i_rd) begin
      if (r_buf_rx_valid) begin
        o_reg_rd_data[7:0] = r_buf_rx_byte;
      end else begin
        o_reg_rd_data = '0;
      end
    end
  end

endmodule
