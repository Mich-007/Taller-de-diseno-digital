`timescale 1ns / 1ps
module immgen_rv32 (
  input  logic [31:0] instr_d,
  input  logic [1:0]  ImmSel,   // 00: I, 01: S, 10: SB, 11: J
  output logic [31:0] imm
);
    // División estándar de instrucción RISC-V
    logic [4:0]  rd     = instr_d[11:7];
    logic [2:0]  funct3 = instr_d[14:12];
    logic [4:0]  rs1    = instr_d[19:15];
    logic [4:0]  rs2    = instr_d[24:20];
    logic [6:0]  funct7 = instr_d[31:25];
    logic [6:0]  opcode = instr_d[6:0];

    // Inmediatos de 32 bits
    logic [31:0] imm_I, imm_S, imm_SB, imm_J;

    // tipo-I: imm[11:0]
    assign imm_I  = {{20{instr_d[31]}}, instr_d[31:20]};

    // tipo-S: imm[11:5] y imm[4:0]
    assign imm_S = {{20{instr_d[31]}}, instr_d[31:25], instr_d[11:7]};

    // tipo-SB: imm[12] imm[11] imm[10:5] y imm[4:1]
    assign imm_SB = {{19{instr_d[31]}},
                 instr_d[31], 
                 instr_d[7],
                 instr_d[30:25], 
                 instr_d[11:8],
                 1'b0};

    // tipo-J (jal): imm[20] imm[19:12] imm[11] y imm[10:1]
    assign imm_J  = {{11{instr_d[31]}},
                 instr_d[31],
                 instr_d[19:12],
                 instr_d[20],
                 instr_d[30:21],
                 1'b0};
                 
    // Selección de inmediato según instrucción
    always_comb begin
      unique case (ImmSel)
        2'b00: imm = {imm_I};
        2'b01: imm = {imm_S};
        2'b10: imm = {imm_SB};
        2'b11: imm = {imm_J};
        default: imm = '0;
      endcase
    end
endmodule

