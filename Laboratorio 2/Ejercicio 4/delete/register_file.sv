// register_file.sv
// Banco de registros parametrizable
// - 2ⁿ registros de W bits
// - Escritura controlada por 'we'
// - Lectura doble por 'addr_rs1' y 'addr_rs2'
// - Registro 0x00 es de solo lectura y siempre devuelve 0
// - Reset síncrono
___________________________________________________________________________________________________________________

module register_file #(
  parameter int N = 4,   // bits de dirección → 2ⁿ registros como se indiccó
  parameter int W = 16   // ancho de palabra en bits
)(
  input  logic             clk,        // reloj
  input  logic             rst,        // reset síncrono
  input  logic             we,         // write enable

//Direcciones
  input  logic [N-1:0]     addr_rd,    // dirección de escritura
  input  logic [N-1:0]     addr_rs1,   // dirección de lectura 1
  input  logic [N-1:0]     addr_rs2,   // dirección de lectura 2

//Datos
  input  logic [W-1:0]     data_in,    // dato a escribir

//Salida
  output logic [W-1:0]     rs1,        // salida lectura 1
  output logic [W-1:0]     rs2         // salida lectura 2
);

  // ___________________________________________________________________________________________________________________
  // 1. Declaración del arreglo de registros
  // ___________________________________________________________________________________________________________________
  logic [W-1:0] regs [2**N];  // 2ⁿ registros de W bits

  // ___________________________________________________________________________________________________________________
  // 2. Lógica de escritura con protección del registro 0
  // ___________________________________________________________________________________________________________________
  always_ff @(posedge clk) begin
    if (rst) begin
      // Reset: poner todos los registros en cero
      regs <= '{default: 0};
    end else if (we && addr_rd != 0) begin
      // Escritura solo si 'we' está en alto y no es reg0
      regs[addr_rd] <= data_in;
    end
  end

  // ___________________________________________________________________________________________________________________
  // 3. Lógica de lectura doble
  // ___________________________________________________________________________________________________________________
  always_comb begin
    // Si se lee reg0, devolver 0
    rs1 = (addr_rs1 == 0) ? '0 : regs[addr_rs1];
    rs2 = (addr_rs2 == 0) ? '0 : regs[addr_rs2];
  end

endmodule
