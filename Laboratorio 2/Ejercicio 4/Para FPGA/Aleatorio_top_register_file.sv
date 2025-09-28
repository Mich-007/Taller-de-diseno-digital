// _________________________________________________________________
// top_register_file.sv
// Módulo superior para probar el banco de registros en FPGA
// - Control por switches y botones
// - Visualización en display de 7 segmentos
// - Generación de datos aleatorios con LFSR corregido
// _________________________________________________________________

//Nombre del modulo
module top_register_file (
  input  logic        clk,         // Reloj de 100 MHz
  input  logic [15:0] sw,          // Switches: direcciones
  input  logic [4:0]  btn,         // Botones: control
  output logic [6:0]  seg,         // Segmentos del display
  output logic [7:0]  an           // Ánodos del display
);

  localparam int N = 4;
  localparam int W = 8;

  // Señales internas
  logic rst_raw, we_raw, sel_rs_raw;
  logic rst, we, sel_rs;
  logic [N-1:0] addr_rd, addr_rs1, addr_rs2;
  logic [W-1:0] data_in, rs1, rs2, rand_val;
  logic [15:0] disp_val;

  // Botones sin debounce
  assign rst_raw    = btn[0];
  assign we_raw     = btn[1];
  assign sel_rs_raw = btn[2];

  // Debounce para cada botón
  debounce db_rst    (.clk(clk), .btn(rst_raw),    .db_out(rst));
  debounce db_we     (.clk(clk), .btn(we_raw),     .db_out(we));
  debounce db_sel_rs (.clk(clk), .btn(sel_rs_raw), .db_out(sel_rs));

  // Switches → direcciones
  assign addr_rd  = sw[3:0];
  assign addr_rs1 = sw[7:4];
  assign addr_rs2 = sw[11:8];

  // Generador aleatorio corregido
  lfsr lfsr_inst (
    .clk(clk),
    .rst(rst),
    .rand_out(rand_val) // ← nombre corregido
  );

  assign data_in = rand_val;

  // Banco de registros
  register_file #(.N(N), .W(W)) rf_inst (
    .clk(clk),
    .rst(rst),
    .we(we),
    .addr_rd(addr_rd),
    .addr_rs1(addr_rs1),
    .addr_rs2(addr_rs2),
    .data_in(data_in),
    .rs1(rs1),
    .rs2(rs2)
  );

  // Selección de salida
  assign disp_val = {8'b0, (sel_rs ? rs2 : rs1)};

  // Display
  seven_seg_driver sseg (
    .clk(clk),
    .val(disp_val),
    .seg(seg),
    .an(an)
  );

endmodule
