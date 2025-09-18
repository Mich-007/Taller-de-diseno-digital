// _________________________________________________________________
// top_register_file.sv (corregido)
// - Reset síncrono efectivo combinado con debounce
// - Parametrización propagada
// _________________________________________________________________

module top_register_file #(                          // inicio del módulo parametrizado
  localparam int N = 4,                              // N: ancho de dirección (2^N registros)
  localparam int W = 8,                              // W: ancho de palabra en bits
  localparam int DIGITS = 4                          // DIGITS: dígitos multiplexados del display
)(
  input  logic        clk,         // reloj del sistema (ej. 100 MHz) - entrada física
  input  logic        rst,         // reset externo (activo alto) - entrada física
  input  logic [15:0] sw,          // switches físicos, usados como direcciones y controles
  input  logic [4:0]  btn,         // botones físicos (ej. btn[0]=reset, btn[1]=we, btn[2]=sel_rs)
  output logic [6:0]  seg,         // salidas para segmentos del 7-seg (7 bits)
  output logic [7:0]  an           // salidas para ánodos del display multiplexado (8 dígitos)
);

  // señales internas
  logic rst_raw, we_raw, sel_rs_raw;                 // señales crudas directamente desde botones
  logic rst_btn, we, sel_rs;                         // señales tras pasar por debounce
  logic rst_effective;                               // reset efectivo = rst externo OR btn reset
  logic [N-1:0] addr_rd, addr_rs1, addr_rs2;         // direcciones para escritura y dos lecturas
  logic [W-1:0] data_in, rs1, rs2, rand_val;         // data_in hacia RF, salidas rs1/rs2, LFSR rand_val
  logic [DIGITS*4-1:0] disp_val;                     // valor empaquetado en nibbles para el display

  // botones sin debounce
  assign rst_raw    = btn[0];                        // btn[0] se usa como pulsador de reset (sin filtrar)
  assign we_raw     = btn[1];                        // btn[1] se usa para señal de write enable cruda
  assign sel_rs_raw = btn[2];                        // btn[2] selecciona si se muestra rs1 o rs2 en display

  // debounce (usar rst externo para inicializar)
  debounce #(.CNT_WIDTH(18), .THRESH(200000)) db_rst    (.clk(clk), .rst(rst), .btn(rst_raw),    .db_out(rst_btn));
                                                     // instancia debounce para el botón de reset
  debounce #(.CNT_WIDTH(18), .THRESH(200000)) db_we     (.clk(clk), .rst(rst), .btn(we_raw),     .db_out(we));
                                                     // instancia debounce para write enable
  debounce #(.CNT_WIDTH(18), .THRESH(200000)) db_sel_rs (.clk(clk), .rst(rst), .btn(sel_rs_raw), .db_out(sel_rs));
                                                     // instancia debounce para select rs

  // rst_effective = reset externo o pulsador de reset
  assign rst_effective = rst | rst_btn;              // combina reset externo con pulsador filtrado

  // switches -> direcciones (usar N bits)
  assign addr_rd  = sw[3:0];                         // lower bits de sw -> dirección de escritura (N = 4)
  assign addr_rs1 = sw[7:4];                         // siguientes 4 bits -> dirección rs1
  assign addr_rs2 = sw[11:8];                        // siguientes 4 bits -> dirección rs2

  // LFSR parametrizado (enable=1 para generar continuamente)
  lfsr #(.WIDTH(W)) lfsr_inst (                      // instancia LFSR parametrizable por W
    .clk(clk),                                       // reloj de entrada para desplazar LFSR
    .rst(rst_effective),                             // reset síncrono para inicializar LFSR
    .en(1'b1),                                       // enable permanente para generar valores continuamente
    .rand_out(rand_val)                              // salida pseudoaleatoria W bits
  );

  assign data_in = rand_val;                         // data_in alimentado por la salida del LFSR

  // Banco de registros
  register_file #(.N(N), .W(W)) rf_inst (            // instancia del register file parametrizado
    .clk(clk),                                       // reloj del banco de registros
    .rst(rst_effective),                             // reset efectivo para inicializar registros
    .we(we),                                         // señal de escritura (desde debounce)
    .addr_rd(addr_rd),                               // dirección de escritura
    .addr_rs1(addr_rs1),                             // dirección lectura rs1
    .addr_rs2(addr_rs2),                             // dirección lectura rs2
    .data_in(data_in),                               // dato a escribir por we
    .rs1(rs1),                                       // salida lectura rs1
    .rs2(rs2)                                        // salida lectura rs2
  );

  // empaquetado para display: nibbles bajos (si W < DIGITS*4 se ceros a la izquierda)
  assign disp_val = {{(DIGITS*4 - W){1'b0}}, (sel_rs ? rs2 : rs1)};
                                                     // concatena ceros para rellenar y escoge rs2 o rs1 según sel_rs

  // driver de 7 segmentos
  seven_seg_driver #(.DIGITS(DIGITS), .REFRESH_CNT_WIDTH(16)) sseg (
    .clk(clk),                                       // reloj para multiplexado y refresco
    .rst(rst_effective),                             // reset para reiniciar contadores internos del driver
    .val(disp_val),                                  // valor empaquetado que se mostrará en pantalla
    .seg(seg),                                       // salidas de segmentos (7 bits)
    .an(an)                                          // salidas de ánodos (DIGITS bits)
  );

endmodule                                            // fin del módulo
