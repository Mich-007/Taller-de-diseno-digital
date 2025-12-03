`timescale 1ns / 1ps
module Memoria_inst #(
  parameter DEPTH = 512   // 512 palabras = 2 KiB (0x0000..0x07FF)
)(
  input  logic [8:0] a,       // índice de palabra: ProgAddress_o[10:2]
  input  logic       clk,     // ojito, se puede quitar y hacer combinacional
  output logic [31:0] spo
);

  // memoria por palabras
  logic [31:0] mem [0:DEPTH-1];
  logic [31:0] spo_reg;

  // inicializar desde program.hex
  initial begin

    $readmemh("program.hex", mem);
  end

  // lectura síncrona: salida disponible 1 ciclo después de la dirección
  always_ff @(posedge clk) begin
    spo_reg <= mem[a];
  end

  assign spo = spo_reg;

endmodule
