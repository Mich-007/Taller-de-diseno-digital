// lfsr16.sv
`timescale 1ns/1ps
// LFSR 16-bit: polinomio x^16 + x^14 + x^13 + x^11 + 1 (máxima longitud).
module lfsr16(
    input  logic        clk,
    input  logic        rst,       // activo alto
    output logic [15:0] random
);
    logic [15:0] r;
    logic feedback;

    assign feedback = r[15] ^ r[13] ^ r[12] ^ r[10];
    assign random   = r;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)    r <= 16'h0001;      // Semilla no nula
        else        r <= {r[14:0], feedback};
    end
endmodule
