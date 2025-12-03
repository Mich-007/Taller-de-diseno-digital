`timescale 1ns / 1ps
module control_global #(
    parameter bit Simulacion = 0
)(
    input  logic        clk,
    input  logic        reset,

    // campos de instrucción desde datapath/IR
    input  logic [6:0]  opcode,
    input  logic [2:0]  funct3,
    input  logic [6:0]  funct7,

    // Salidas de control
    output logic        PCWriteCond,
    output logic        PCWrite,
    output logic [1:0]  PCSource,

    output logic        MemRead,
    output logic        MemWrite,

    output logic [1:0]  MemtoReg,
    output logic        RegWrite,

    output logic        IorD,
    output logic        IRWrite,

    output logic [1:0]  ALUSrcA,
    output logic [1:0]  ALUSrcB,
    output logic [1:0]  ALUOp,

    output logic        LatchAB,
    output logic        ALUOutEn,

    output logic [2:0]  ImmSrc,

    output logic [3:0]  st_dbg   // debug state
);

    // FSM states
    typedef enum logic [3:0] {
        S_RESET = 4'd0,
        S_IF    = 4'd1,
        S_ID    = 4'd2,
        S_EX    = 4'd3,
        S_MEM   = 4'd4,
        S_WB    = 4'd5,
        S_MEM_WR= 4'd6,
        S_JUMP  = 4'd7
    } state_t;

    state_t state, next_state;

    // Opcodes of interest (RV32I)
    localparam logic [6:0] OP_LUI    = 7'b0110111;
    localparam logic [6:0] OP_AUIPC  = 7'b0010111;
    localparam logic [6:0] OP_JAL    = 7'b1101111;
    localparam logic [6:0] OP_JALR   = 7'b1100111;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_LOAD   = 7'b0000011;
    localparam logic [6:0] OP_STORE  = 7'b0100011;
    localparam logic [6:0] OP_OP_IMM = 7'b0010011;
    localparam logic [6:0] OP_OP     = 7'b0110011;
    localparam logic [6:0] OP_MISC_MEM = 7'b0001111; // not used
    localparam logic [6:0] OP_SYSTEM = 7'b1110011; // not used

    // Helper signals
    logic is_load, is_store, is_branch, is_rtype, is_itype, is_jal, is_jalr, is_lui, is_auipc;

    always_comb begin
        is_load  = (opcode == OP_LOAD);
        is_store = (opcode == OP_STORE);
        is_branch= (opcode == OP_BRANCH);
        is_rtype = (opcode == OP_OP);
        is_itype = (opcode == OP_OP_IMM) || (opcode == OP_JALR);
        is_jal   = (opcode == OP_JAL);
        is_jalr  = (opcode == OP_JALR);
        is_lui   = (opcode == OP_LUI);
        is_auipc = (opcode == OP_AUIPC);
    end

    // FSM sequential
    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= S_RESET;
        else state <= next_state;
    end

    // Next state logic (simple multicycle)
    always_comb begin
        // default next
        next_state = state;

        case (state)
            S_RESET: next_state = S_IF;
            S_IF:    next_state = S_ID;
            S_ID:    begin
                // decide next based on opcode
                if (is_rtype || is_itype || is_lui || is_auipc) next_state = S_EX;
                else if (is_load || is_store) next_state = S_EX;
                else if (is_branch) next_state = S_EX;
                else if (is_jal || is_jalr) next_state = S_JUMP;
                else next_state = S_IF; // unknown -> fetch next
            end
            S_EX: begin
                if (is_load) next_state = S_MEM;
                else if (is_store) next_state = S_MEM_WR;
                else next_state = S_WB;
            end
            S_MEM: next_state = S_WB;
            S_MEM_WR: next_state = S_IF;
            S_WB: next_state = S_IF;
            S_JUMP: next_state = S_IF;
            default: next_state = S_IF;
        endcase
    end

    // Default control outputs
    always_comb begin
        // defaults
        PCWriteCond = 1'b0;
        PCWrite     = 1'b0;
        PCSource    = 2'b00;

        MemRead     = 1'b0;
        MemWrite    = 1'b0;

        MemtoReg    = 2'b00;
        RegWrite    = 1'b0;

        IorD        = 1'b0;
        IRWrite     = 1'b0;

        ALUSrcA     = 2'b00;
        ALUSrcB     = 2'b00;
        ALUOp       = 2'b00;

        LatchAB     = 1'b0;
        ALUOutEn    = 1'b0;

        ImmSrc      = 3'b000;

        st_dbg      = 4'h0;

        // state-specific outputs
        case (state)
            S_IF: begin
                // Fetch: MemRead from instruction memory, IRWrite, ALU computes PC+4
                MemRead  = 1'b1;
                IRWrite  = 1'b1;
                IorD     = 1'b0;      // address = PC
                ALUSrcA  = 2'b00;     // A = PC
                ALUSrcB  = 2'b01;     // B = 4
                ALUOp    = 2'b00;     // ADD
                ALUOutEn = 1'b1;
                PCWrite  = 1'b1;      // update PC with PC+4 (some FSM use PCWrite in IF)
                PCSource = 2'b00;     // PC <- PC+4
                st_dbg   = 4'h1;
            end

            S_ID: begin
                // Decode: latch registers A and B, generate immediate
                LatchAB  = 1'b1;
                ALUSrcA  = 2'b00;     // A = PC (for AUIPC) but latchAB used for registers
                ALUSrcB  = 2'b00;
                ALUOp    = 2'b00;
                ImmSrc   = 3'b000;    // decoder in datapath will use ImmSrc to select type
                st_dbg   = 4'h2;
            end

            S_EX: begin
                // Execute: depends on instruction type
                LatchAB  = 1'b0;
                ALUOutEn = 1'b1;
                st_dbg   = 4'h3;

                if (is_rtype) begin
                    // R-type: ALU uses A and B
                    ALUSrcA = 2'b01; // A = reg A
                    ALUSrcB = 2'b00; // B = reg B
                    ALUOp   = 2'b10; // R-type decode
                end else if (is_itype && !is_jalr) begin
                    // I-type arithmetic (addi, andi, ori, etc.)
                    ALUSrcA = 2'b01; // A = reg A
                    ALUSrcB = 2'b10; // B = Imm
                    ALUOp   = 2'b11; // I-type arithmetic
                end else if (is_load || is_store) begin
                    // address calculation: A = reg A, B = imm
                    ALUSrcA = 2'b01;
                    ALUSrcB = 2'b10;
                    ALUOp   = 2'b00; // ADD for address calc
                end else if (is_branch) begin
                    // branch: compute A - B
                    ALUSrcA = 2'b01;
                    ALUSrcB = 2'b00;
                    ALUOp   = 2'b01; // SUB for branch compare
                end else if (is_jalr) begin
                    // jalr: compute rs1 + imm
                    ALUSrcA = 2'b01;
                    ALUSrcB = 2'b10;
                    ALUOp   = 2'b00; // ADD
                end else if (is_lui) begin
                    // LUI: handled in WB (imm << 12)
                    ALUSrcA = 2'b00;
                    ALUSrcB = 2'b10;
                    ALUOp   = 2'b00;
                end else if (is_auipc) begin
                    // AUIPC: PC + imm
                    ALUSrcA = 2'b00; // PC
                    ALUSrcB = 2'b10; // imm
                    ALUOp   = 2'b00;
                end
            end

            S_MEM: begin
                // Memory access for loads
                st_dbg = 4'h4;
                // For load: MemRead asserted, IorD selects ALUOut as address
                MemRead = 1'b1;
                IorD    = 1'b1;   // address = ALUOut
                // Data will be read and then WB
            end

            S_MEM_WR: begin
                // Memory write for stores
                st_dbg = 4'h6;
                MemWrite = 1'b1;
                IorD     = 1'b1;  // address = ALUOut
                // After write, go to IF
            end

            S_WB: begin
                // Write back stage
                st_dbg = 4'h5;
                if (is_load) begin
                    // load: write memory data to register
                    MemtoReg = 2'b01; // DataIn
                    RegWrite = 1'b1;
                end else if (is_rtype || is_itype) begin
                    // ALU result to register
                    MemtoReg = 2'b00; // ALUOut
                    RegWrite = 1'b1;
                end else if (is_jal || is_jalr) begin
                    // write PC+4 to rd
                    MemtoReg = 2'b10; // PC+4
                    RegWrite = 1'b1;
                end else if (is_lui) begin
                    // LUI: imm to rd (handled in datapath imm logic)
                    MemtoReg = 2'b00;
                    RegWrite = 1'b1;
                end else if (is_auipc) begin
                    MemtoReg = 2'b00;
                    RegWrite = 1'b1;
                end
            end

            S_JUMP: begin
                // Jumps: JAL and JALR update PC and write PC+4 to rd
                st_dbg = 4'h7;
                PCWrite = 1'b1;
                if (is_jal) begin
                    // PC <- PC + imm (ALUOut computed in EX)
                    PCSource = 2'b01; // ALUOut
                end else if (is_jalr) begin
                    // PC <- ALUResult masked (in datapath)
                    PCSource = 2'b10;
                end
                // write PC+4 to rd in WB stage (we can set RegWrite in WB)
            end

            default: begin
                // fallback to IF
                st_dbg = 4'h0;
            end
        endcase
    end

    // PCWriteCond: only asserted in ID/EX when branch decision is made
    always_comb begin
        PCWriteCond = 1'b0;
        if (state == S_EX && is_branch) begin
            // control asserts PCWriteCond; datapath must evaluate branch condition
            PCWriteCond = 1'b1;
        end
    end

endmodule
