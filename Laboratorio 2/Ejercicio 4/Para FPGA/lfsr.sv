// ============================================================
// lfsr.sv
// Generador pseudoaleatorio basado en LFSR (Linear Feedback Shift Register)
// - Produce una secuencia de 8 bits en hardware
// - Funciona en tiempo real en la FPGA
// ============================================================

module lfsr (
  input  logic clk,           // Reloj del sistema
  input  logic rst,           // Reset para reiniciar la secuencia
  output logic [7:0] rand_out // Salida pseudoaleatoria corregida
);

  logic [7:0] lfsr_reg;

  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      lfsr_reg <= 8'h1; // Semilla inicial (no puede ser 0)
    else
      // Retroalimentación XOR entre bit 7 y bit 5
      lfsr_reg <= {lfsr_reg[6:0], lfsr_reg[7] ^ lfsr_reg[5]};
  end

  assign rand_out = lfsr_reg;

endmodule
