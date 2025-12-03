`timescale 1ns / 1ps
module ALU #(
    parameter int XLEN = 32
)(
    input  logic [XLEN-1:0] A,
    input  logic [XLEN-1:0] B,
    input  logic [1:0]      Op,    // 00=ADD, 01=SUB, 10=AND, 11=OR
    output logic [XLEN-1:0] ALUOut,
    output logic            Zero
);

    logic signed [XLEN-1:0] As;
    logic signed [XLEN-1:0] Bs;
    logic [XLEN-1:0]        result;

    assign As = A;
    assign Bs = B;

    always_comb begin
        unique case (Op)
            2'b00: result = A + B;        // ADD
            2'b01: result = A - B;        // SUB
            2'b10: result = A & B;        // AND
            2'b11: result = A | B;        // OR
            default: result = A + B;
        endcase
    end

    assign ALUOut = result;
    assign Zero   = (result == {XLEN{1'b0}});

endmodule
