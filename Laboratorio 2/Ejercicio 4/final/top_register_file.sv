// _________________________________________________________________
// top_register_file.sv (corregido)
// - Reset síncrono efectivo combinado con debounce
// - Parametrización propagada
// _________________________________________________________________

module top_register_file #(
  localparam int N = 4,
  localparam int W = 8,
  localparam int DIGITS = 4
)(
  input  logic        clk,         // reloj de 100 MHz (ej.)
  input  logic        rst,         // reset síncrono activo alto (externo)
  input  logic [15:0] sw,          // switches
  input  logic [4:0]  btn,         // botones
  output logic [6:0]  seg,         // segmentos
  output logic [7:0]  an           // ánodos
);

  // señales internas
  logic rst_raw, we_raw, sel_rs_raw;
  logic rst_btn, we, sel_rs;
  logic rst_effective;
  logic [N-1:0] addr_rd, addr_rs1, addr_rs2;
  logic [W-1:0] data_in, rs1, rs2, rand_val;
  logic [DIGITS*4-1:0] disp_val;

  // botones sin debounce
  assign rst_raw    = btn[0];
  assign we_raw     = btn[1];
  assign sel_rs_raw = btn[2];

  // debounce (usar rst externo para inicializar)
  debounce #(.CNT_WIDTH(18), .THRESH(200000)) db_rst    (.clk(clk), .rst(rst), .btn(rst_raw),    .db_out(rst_btn));
  debounce #(.CNT_WIDTH(18), .THRESH(200000)) db_we     (.clk(clk), .rst(rst), .btn(we_raw),     .db_out(we));
  debounce #(.CNT_WIDTH(18), .THRESH(200000)) db_sel_rs (.clk(clk), .rst(rst), .btn(sel_rs_raw), .db_out(sel_rs));

  // rst_effective = reset externo o pulsador de reset
  assign rst_effective = rst | rst_btn;

  // switches -> direcciones (usar N bits)
  assign addr_rd  = sw[3:0];
  assign addr_rs1 = sw[7:4];
  assign addr_rs2 = sw[11:8];

  // LFSR parametrizado (enable=1 para generar continuamente)
  lfsr #(.WIDTH(W)) lfsr_inst (
    .clk(clk),
    .rst(rst_effective),
    .en(1'b1),
    .rand_out(rand_val)
  );

  assign data_in = rand_val;

  // Banco de registros
  register_file #(.N(N), .W(W)) rf_inst (
    .clk(clk),
    .rst(rst_effective),
    .we(we),
    .addr_rd(addr_rd),
    .addr_rs1(addr_rs1),
    .addr_rs2(addr_rs2),
    .data_in(data_in),
    .rs1(rs1),
    .rs2(rs2)
  );

  // empaquetado para display: nibbles bajos (si W < DIGITS*4 se ceros a la izquierda)
  assign disp_val = {{(DIGITS*4 - W){1'b0}}, (sel_rs ? rs2 : rs1)};

  // driver de 7 segmentos
  seven_seg_driver #(.DIGITS(DIGITS), .REFRESH_CNT_WIDTH(16)) sseg (
    .clk(clk),
    .rst(rst_effective),
    .val(disp_val),
    .seg(seg),
    .an(an)
  );

endmodule
