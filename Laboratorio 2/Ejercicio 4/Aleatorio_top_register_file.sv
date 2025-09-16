// _______________________________________________________________
// top_register_file.sv
// Módulo superior para probar el banco de registros en FPGA
// - Control por switches y botones
// - Visualización en display de 7 segmentos
// - Generación de datos aleatorios con LFSR
// _______________________________________________________________

module top_register_file (
  input  logic        clk,         // Reloj de 100 MHz
  input  logic [15:0] sw,          // Switches: direcciones
  input  logic [4:0]  btn,         // Botones: control
  output logic [6:0]  seg,         // Segmentos del display
  output logic [7:0]  an           // Ánodos del display
);

  // _______________________________________________________________
  // 1. Parámetros del banco de registros
  // _______________________________________________________________
  localparam int N = 4;            // 2ⁿ = 16 registros
  localparam int W = 8;            // 8 bits por registro

  // _______________________________________________________________
  // 2. Señales internas
  // _______________________________________________________________
  logic rst, we, sel_rs;           // Control por botones
  logic [N-1:0] addr_rd;           // Dirección de escritura
  logic [N-1:0] addr_rs1;          // Dirección de lectura 1
  logic [N-1:0] addr_rs2;          // Dirección de lectura 2
  logic [W-1:0] data_in;           // Dato a escribir
  logic [W-1:0] rs1, rs2;          // Salidas de lectura
  logic [W-1:0] rand_val;          // Valor aleatorio generado
  logic [15:0] disp_val;           // Valor extendido para display

  // _______________________________________________________________
  // 3. Asignación de botones
  // _______________________________________________________________
  assign rst    = btn[0];          // Reset general
  assign we     = btn[1];          // Activar escritura
  assign sel_rs = btn[2];          // Seleccionar salida: rs1 o rs2

  // _______________________________________________________________
  // 4. Asignación de switches
  // _______________________________________________________________
  assign addr_rd  = sw[3:0];       // Dirección de escritura
  assign addr_rs1 = sw[7:4];       // Dirección de lectura 1
  assign addr_rs2 = sw[11:8];      // Dirección de lectura 2

  // _______________________________________________________________
  // 5. Generador pseudoaleatorio (LFSR)
  // _______________________________________________________________
  // Produce un nuevo valor aleatorio en cada ciclo de reloj
  lfsr lfsr_inst (
    .clk(clk),
    .rst(rst),
    .rand(rand_val)
  );

  assign data_in = rand_val;       // Usar valor aleatorio como entrada

  // _______________________________________________________________
  // 6. Instancia del banco de registros
  // _______________________________________________________________
  // Escritura controlada por 'we', lectura doble por rs1 y rs2
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

  // _______________________________________________________________
  // 7. Selección de salida para mostrar en el display
  // _______________________________________________________________
  // Si btn[2] está en alto, se muestra rs2; si no, rs1
  always_comb begin
    disp_val = {8'b0, (sel_rs ? rs2 : rs1)}; // extender a 16 bits
  end

  // _______________________________________________________________
  // 8. Instancia del controlador de display de 7 segmentos
  // _______________________________________________________________
  // Muestra el valor leído en formato hexadecimal
  seven_seg_driver sseg (
    .clk(clk),
    .val(disp_val),
    .seg(seg),
    .an(an)
  );

endmodule
