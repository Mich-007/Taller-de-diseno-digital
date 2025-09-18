// ============================================================
// lfsr.sv
// LFSR parametrizable, reset síncrono, enable, salida WIDTH bits
// - Para WIDTH=8 se usan taps que dan periodo máximo (255)
// ============================================================

module lfsr #(
  parameter int WIDTH = 8,
  parameter logic [WIDTH-1:0] SEED = { {(WIDTH-1){1'b0}}, 1'b1 }
)(
  input  logic clk,
  input  logic rst,         // reset síncrono activo alto
  input  logic en,          // enable para avanzar
  output logic [WIDTH-1:0] rand_out
);

  logic [WIDTH-1:0] lfsr_reg;
  logic feedback;

  always_ff @(posedge clk) begin
    if (rst) begin
      if (SEED == '0) lfsr_reg <= { {(WIDTH-1){1'b0}}, 1'b1 };
      else            lfsr_reg <= SEED;
    end else begin
      if (en) begin
        if (WIDTH == 8) begin
          // taps: x^8 + x^6 + x^5 + x^4 + 1
          feedback = lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3];
          lfsr_reg <= { lfsr_reg[6:0], feedback };
        end else begin
          // fallback simple (funcional pero no primitivo para todos los WIDTH)
          feedback = lfsr_reg[WIDTH-1] ^ lfsr_reg[WIDTH-3];
          lfsr_reg <= { lfsr_reg[WIDTH-2:0], feedback };
        end
      end
    end
  end

  assign rand_out = lfsr_reg;

endmodule
