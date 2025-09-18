// ============================================================
// lfsr.sv
// LFSR parametrizable, reset síncrono, enable, salida WIDTH bits
// - Para WIDTH=8 se usan taps que dan periodo máximo (255)
// ============================================================

module lfsr #(
  parameter int WIDTH = 8,                                 // ancho del registro LFSR en bits
  parameter logic [WIDTH-1:0] SEED = { {(WIDTH-1){1'b0}}, 1'b1 } // semilla por defecto: 0..01 (no todo ceros)
)(
  input  logic clk,                                        // reloj síncrono (flanco posedge usado)
  input  logic rst,                                        // reset síncrono, activo alto: inicializa LFSR
  input  logic en,                                         // enable: cuando es 1 el LFSR avanza en cada flanco
  output logic [WIDTH-1:0] rand_out                        // salida W bits con el estado actual del LFSR
);

  // Registro interno que mantiene el estado del LFSR
  logic [WIDTH-1:0] lfsr_reg;

  // Señal temporal para la retroalimentación (feedback bit) calculada desde taps
  logic feedback;

  // Bloque síncrono que actualiza el registro LFSR en cada flanco de clk
  always_ff @(posedge clk) begin
    if (rst) begin
      // En reset: cargar la semilla definida por el parámetro SEED
      // Si SEED es accidentalmente todo ceros, forzamos una semilla no nula {..,1}
      if (SEED == '0) lfsr_reg <= { {(WIDTH-1){1'b0}}, 1'b1 };
      else            lfsr_reg <= SEED;
    end else begin
      // Si no hay reset, solo avanzar cuando enable está activo
      if (en) begin
        // Caso especial optimizado para WIDTH==8: taps que dan periodo máximo 255
        if (WIDTH == 8) begin
          // Taps seleccionados: x^8 + x^6 + x^5 + x^4 + 1
          // feedback = XOR de bits correspondientes (indices basados en 0)
          // lfsr_reg[7] representa el bit más significativo (x^8 term)
          feedback = lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3];
          // Shifting: concatenar bits [6:0] y el nuevo feedback en LSB
          lfsr_reg <= { lfsr_reg[6:0], feedback };
        end else begin
          // Fallback general simple para otros WIDTH
          // No garantiza máximo periodo para todos los WIDTH; sirve como LFSR funcional
          // Usa taps conservadores: MSB xor MSB-2
          feedback = lfsr_reg[WIDTH-1] ^ lfsr_reg[WIDTH-3];
          // Shift hacia la izquierda por 1 y colocar feedback en LSB
          lfsr_reg <= { lfsr_reg[WIDTH-2:0], feedback };
        end
      end
      // Si en == 0, lfsr_reg conserva su valor (no avanza)
    end
  end

  // Exponer el estado del LFSR como salida (sin registrarlo adicionalmente)
  assign rand_out = lfsr_reg;

endmodule
