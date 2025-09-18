// ============================================================
// register_file.sv
// Banco de registros parametrizable con lectura doble
// - 2^N registros, ancho W
// - Escritura controlada por we
// - Registro 0 protegido (siempre 0)
// - Bypass read-after-write definido
// ============================================================

module register_file #(
  parameter int N = 4,   // bits de dirección -> 2^N registros
  parameter int W = 8    // ancho de palabra
)(
  input  logic             clk,        // reloj del sistema
  input  logic             rst,        // reset síncrono activo alto
  input  logic             we,         // write enable (sincronizado)
  input  logic [N-1:0]     addr_rd,    // dirección de escritura
  input  logic [N-1:0]     addr_rs1,   // dirección lectura 1
  input  logic [N-1:0]     addr_rs2,   // dirección lectura 2
  input  logic [W-1:0]     data_in,    // dato a escribir
  output logic [W-1:0]     rs1,        // salida lectura 1
  output logic [W-1:0]     rs2         // salida lectura 2
);

  localparam int DEPTH = (1 << N);

  logic [W-1:0] regs [0:DEPTH-1];

  // Escritura síncrona con reset síncrono
  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < DEPTH; i = i + 1) regs[i] <= '0;
    end else begin
      if (we && (addr_rd != '0)) regs[addr_rd] <= data_in;
    end
  end

  // Lectura combinacional con bypass (read-after-write)
  always_comb begin
    // rs1
    if (addr_rs1 == '0) rs1 = '0;
    else if (we && (addr_rs1 == addr_rd) && (addr_rd != '0)) rs1 = data_in;
    else rs1 = regs[addr_rs1];

    // rs2
    if (addr_rs2 == '0) rs2 = '0;
    else if (we && (addr_rs2 == addr_rd) && (addr_rd != '0)) rs2 = data_in;
    else rs2 = regs[addr_rs2];
  end

endmodule
