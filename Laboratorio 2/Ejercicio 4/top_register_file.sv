// top_register_file.sv
// Módulo superior para probar el banco de registros en FPGA Nexys4
// - Control por switches y botones
// - Visualización en display de 7 segmentos
// - Compatible con archivo .xdc proporcionado

module top_register_file (
  input  logic        clk,         // reloj de 100 MHz
  input  logic [15:0] sw,          // switches: direcciones y datos
  input  logic [4:0]  btn,         // botones: [0]=reset, [1]=we, [2]=sel_rs
  output logic [6:0]  seg,         // segmentos del display
  output logic [7:0]  an           // ánodos del display
);

  // ____________________________________________________________________________
  // 1. Parámetros del banco de registros
  // ____________________________________________________________________________
  localparam int N = 4;   // 2ⁿ = 16 registros
  localparam int W = 8;   // ancho de palabra (8 bits para visualización)

  // ____________________________________________________________________________
  // 2. Señales internas
  // ____________________________________________________________________________
  logic rst, we, sel_rs;
  logic [N-1:0] addr_rd, addr_rs1, addr_rs2;
  logic [W-1:0] data_in, rs1, rs2;
  logic [W-1:0] disp_val;

  // ____________________________________________________________________________
  // 3. Debounce para botones
  // ____________________________________________________________________________
  // Se usa debounce para evitar rebotes mecánicos en los botones
  debounce db_rst (.clk(clk), .btn(btn[0]), .db_out(rst));
  debounce db_we  (.clk(clk), .btn(btn[1]), .db_out(we));
  debounce db_sel (.clk(clk), .btn(btn[2]), .db_out(sel_rs));

  // ____________________________________________________________________________
  // 4. Instancia del banco de registros
  // ____________________________________________________________________________
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

  // ____________________________________________________________________________
  // 5. Asignación de switches a señales
  // ____________________________________________________________________________
  // sw[3:0]   → dirección de escritura
  // sw[7:4]   → dirección de lectura rs1
  // sw[11:8]  → dirección de lectura rs2
  // sw[15:8]  → dato de entrada (solo se usan los 8 bits superiores)
  assign addr_rd  = sw[3:0];
  assign addr_rs1 = sw[7:4];
  assign addr_rs2 = sw[11:8];
  assign data_in  = sw[15:8];

  // ____________________________________________________________________________
  // 6. Selección de salida a mostrar en el display
  // ___________________________________________________________________________
  // Si btn[2] está en alto, se muestra rs2; si no, rs1
  always_comb begin
    disp_val = (sel_rs) ? rs2 : rs1;
  end

  // ____________________________________________________________________________
  // 7. Driver del display de 7 segmentos
  // ____________________________________________________________________________
  // Muestra el valor seleccionado en formato hexadecimal
  seven_seg_driver sseg (
    .clk(clk),
    .val(disp_val),
    .seg(seg),
    .an(an)
  );

endmodule
