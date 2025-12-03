`timescale 1ns / 1ps
module ALU_Control (
    input  logic [1:0] ALUOp,     // desde control_global
    input  logic [2:0] funct3,    // desde IR
    input  logic [6:0] funct7,    // desde IR
    output logic [3:0] Op        // hacia ALU (ver codificación en ALU)
);

    // En esta parte se mapea instrucciones RV32I a Op
    // ALUOp conventions:
    // 00 -> load/store/addi (use ADD)
    // 01 -> branch (use SUB)
    // 10 -> R-type (use funct3/funct7)
    // 11 -> immediate arithmetic (use funct3)

    always_comb begin
        Op = 4'b0000; // default ADD
        unique case (ALUOp)
            2'b00: Op = 4'b0000; // ADD (lw/sw/addi, auipc address calc)
            2'b01: Op = 4'b0001; // SUB for branch comparison
            2'b10: begin // R-type
                unique case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0100000) Op = 4'b0001; // SUB
                        else Op = 4'b0000; // ADD
                    end
                    3'b111: Op = 4'b0010; // AND
                    3'b110: Op = 4'b0011; // OR
                    3'b100: Op = 4'b0100; // XOR
                    3'b001: Op = 4'b0101; // SLL
                    3'b101: begin
                        if (funct7 == 7'b0100000) Op = 4'b0111; // SRA
                        else Op = 4'b0110; // SRL
                    end
                    3'b010: Op = 4'b1000; // SLT (signed)
                    3'b011: Op = 4'b1001; // SLTU (unsigned)
                    default: Op = 4'b0000;
                endcase
            end
            2'b11: begin // I-type arithmetic (addi, andi, ori, xori, slli, srli, srai, slti, sltiu)
                unique case (funct3)
                    3'b000: Op = 4'b0000; // ADDI
                    3'b111: Op = 4'b0010; // ANDI
                    3'b110: Op = 4'b0011; // ORI
                    3'b100: Op = 4'b0100; // XORI
                    3'b001: Op = 4'b0101; // SLLI
                    3'b101: begin
                        if (funct7 == 7'b0100000) Op = 4'b0111; // SRAI
                        else Op = 4'b0110; // SRLI
                    end
                    3'b010: Op = 4'b1000; // SLTI
                    3'b011: Op = 4'b1001; // SLTIU
                    default: Op = 4'b0000;
                endcase
            end
            default: Op = 4'b0000;
        endcase
    end

endmodule
