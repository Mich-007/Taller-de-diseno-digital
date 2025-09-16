// __________________________________________________________________
// register_file.sv
// Banco de registros parametrizable con lectura doble
// - Número de registros: 2ⁿ
// - Ancho de palabra: W bits
// - Escritura controlada por 'we'
// - Registro 0 protegido (siempre devuelve 0)
// __________________________________________________________________

module register_file #(
  parameter int N = 4,   // Bits de dirección → 2ⁿ registros
  parameter int W = 8    // Ancho de palabra en bits
)(
  input  logic             clk,        // Reloj del sistema
  input  logic             rst,        // Reset síncrono
  
  input  logic             we,         // Write enable
  
  input  logic [N-1:0]     addr_rd,    // Dirección de escritura
  input  logic [N-1:0]     addr_rs1,   // Dirección de lectura 1
  input  logic [N-1:0]     addr_rs2,   // Dirección de lectura 2
  input  logic [W-1:0]     data_in,    // Dato a escribir
  output logic [W-1:0]     rs1,        // Salida lectura 1
  output logic [W-1:0]     rs2         // Salida lectura 2
);

  // Arreglo de registros: 2ⁿ registros de W bits
  logic [W-1:0] regs [2**N];

  // Escritura sincronizada con el reloj
  always_ff @(posedge clk) begin
    if (rst)
      regs <= '{default: 0};          // Reset: todos los registros a 0
    else if (we && addr_rd != 0)
      regs[addr_rd] <= data_in;       // Escritura si 'we' está activo y no es reg0
  end

  // Lectura combinacional: acceso inmediato
  always_comb begin
    rs1 = (addr_rs1 == 0) ? '0 : regs[addr_rs1]; // reg0 siempre devuelve 0
    rs
