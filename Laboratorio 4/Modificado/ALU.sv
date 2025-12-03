`timescale 1ns / 1ps
module ALU #(
    parameter int XLEN = 32
)(
    input  logic [XLEN-1:0] A,
    input  logic [XLEN-1:0] B,
    input  logic [3:0]      Op,    // codificación ampliada
    output logic [XLEN-1:0] ALUOut,
    output logic            Zero
);

    // Op encoding 
    // 4'b0000 ADD
    // 4'b0001 SUB
    // 4'b0010 AND
    // 4'b0011 OR
    // 4'b0100 XOR
    // 4'b0101 SLL
    // 4'b0110 SRL
    // 4'b0111 SRA
    // 4'b1000 SLT (signed)
    // 4'b1001 SLTU (unsigned)
    logic signed [XLEN-1:0] As;
    logic signed [XLEN-1:0] Bs;
    logic [XLEN-1:0] result;
    logic [XLEN-1:0] shamt;

    assign As = A;
    assign Bs = B;
    assign shamt = B[4:0];

    always_comb begin
        unique case (Op)
            4'b0000: result = A + B;                     // ADD
            4'b0001: result = A - B;                     // SUB
            4'b0010: result = A & B;                     // AND
            4'b0011: result = A | B;                     // OR
            4'b0100: result = A ^ B;                     // XOR
            4'b0101: result = A << shamt;                // SLL
            4'b0110: result = A >> shamt;                // SRL logical (in Verilog >> is logical for unsigned)
            4'b0111: result = As >>> shamt;              // SRA arithmetic
            4'b1000: result = (As < Bs) ? {{(XLEN-1){1'b0}},1'b1} : {XLEN{1'b0}}; // SLT signed -> 1 or 0
            4'b1001: result = (A < B) ? {{(XLEN-1){1'b0}},1'b1} : {XLEN{1'b0}};   // SLTU unsigned
            default: result = A + B;
        endcase
    end

    assign ALUOut = result;
    assign Zero   = (result == {XLEN{1'b0}});

endmodule
