// _________________________________________________________________
// top_register_file.sv
// Módulo superior para probar el banco de registros en FPGA
// - Control por switches y botones
// - Visualización en display de 7 segmentos
// - Generación de datos aleatorios con LFSR
// _________________________________________________________________

module top_register_file (
  input  logic        clk,         // Reloj de 100 MHz
  input  logic [15:0] sw,          // Switches: direcciones
  input  logic [4:0]  btn,         // Botones: control
  output logic [6:0]  seg,         // Segmentos del display
  output logic [7:0]  an           // Ánodos del display
);

  localparam int N = 4;            // 16 registros
  localparam int W = 8;            // 8 bits por registro

  // Señales internas
  logic rst, we, sel_rs;
  logic [N-1:0] addr_rd, addr_rs1, addr_rs2;
  logic [W-1:0] data_in, rs1, rs2, rand_val, disp_val;

  // Asignación de botones
  assign rst    = btn[0];          // Reset
  assign we     = btn[1];          // Write enable
  assign sel_rs = btn[2];          // Selección de salida

  // Asignación de switches
  assign addr_rd  = sw[3:0];       // Dirección de escritura
  assign addr_rs1 = sw[7:4];       // Dirección de lectura 1
  assign addr_rs2 = sw[11:8];      // Dirección de lectura 2

  // Generador aleatorio
  lfsr lfsr_inst (
    .clk(clk),
    .rst(rst),
    .rand(rand_val)
  );

  assign data_in = rand_val;       // Usar valor aleatorio como
