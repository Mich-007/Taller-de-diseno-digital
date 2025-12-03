`timescale 1ns / 1ps
module ALU_Control (
    input  logic [1:0] ALUOp,     // desde control_global
    input  logic [2:0] funct3,    // desde IR
    input  logic [6:0] funct7,    // desde IR
    output logic [1:0] Op        // hacia ALU (00=ADD,01=SUB,10=AND,11=OR)
);

    // Op mapping:
    // 00 -> ADD
    // 01 -> SUB
    // 10 -> AND
    // 11 -> OR

    always_comb begin
        // default
        Op = 2'b00;
        unique case (ALUOp)
            2'b00: begin
                // Load/Store/Immediate arithmetic: usar ADD for address calc or addi
                Op = 2'b00; // ADD
            end
            2'b01: begin
                // Branches: use SUB to compute A-B and check Zero
                Op = 2'b01; // SUB
            end
            2'b10: begin
                // R-type: decode funct3/funct7 for add/sub/and/or
                unique case (funct3)
                    3'b000: begin
                        // ADD or SUB depending on funct7
                        if (funct7 == 7'b0100000) Op = 2'b01; // SUB
                        else Op = 2'b00; // ADD
                    end
                    3'b111: Op = 2'b10; // AND
                    3'b110: Op = 2'b11; // OR
                    default: Op = 2'b00; // fallback ADD
                endcase
            end
            default: Op = 2'b00;
        endcase
    end

endmodule
