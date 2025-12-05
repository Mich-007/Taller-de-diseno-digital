`timescale 1ns / 1ps
module control_unit (
  // desde IR
  input  logic [6:0]  opcode,
  input  logic [2:0]  funct3,
  input  logic [6:0]  funct7,

  // desde ALU 
  input  logic        Zero,
  input  logic        less,

  // a datapath
  output logic        RegWrite,
  output logic [1:0]  ImmSrc,
  output logic        ALUSrc,
  output logic        MemWrite,
  output logic [1:0]  ResultSrc,
  output logic        PCSrc,
  output logic [3:0]  ALUControl,
  output logic        Jump
  );

  logic Branch;
  logic [1:0] ALUOp;

// opcodes base
  localparam logic [6:0]
    OPC_RTYPE = 7'b0110011,
    OPC_ITYPE = 7'b0010011,
    OPC_LOAD  = 7'b0000011,
    OPC_STORE = 7'b0100011,
    OPC_BRANCH= 7'b1100011,
    OPC_JAL   = 7'b1101111;
    
    //-----------------------------------------------------
    //                    Main Decoder
    //-----------------------------------------------------
    
    always_comb begin
    case(opcode)
        OPC_LOAD   : begin 
            RegWrite  = 1'b1;
            ImmSrc    = 2'b00;
            ALUSrc    = 1'b1;
            MemWrite  = 1'b0;
            ResultSrc = 2'b01;
            Branch    = 1'b0;
            ALUOp     = 2'b00;
            Jump      = 1'b0;
        end           
        OPC_STORE  : begin 
            RegWrite  = 1'b0;
            ImmSrc    = 2'b01;
            ALUSrc    = 1'b1;
            MemWrite  = 1'b1;
            ResultSrc = 2'b00;
            Branch    = 1'b0;
            ALUOp     = 2'b00;
            Jump      = 1'b0;
        end
        OPC_RTYPE  : begin 
            RegWrite  = 1'b1;
            ImmSrc    = 2'b00;
            ALUSrc    = 1'b0;
            MemWrite  = 1'b0;
            ResultSrc = 2'b00;
            Branch    = 1'b0;
            ALUOp     = 2'b10;
            Jump      = 1'b0;
        end
        OPC_BRANCH :begin 
            RegWrite  = 1'b0;
            ImmSrc    = 2'b10;
            ALUSrc    = 1'b0;
            MemWrite  = 1'b0;
            ResultSrc = 2'b00;
            Branch    = 1'b1;
            ALUOp     = 2'b01;
            Jump      = 1'b0;
        end
        OPC_ITYPE  : begin 
            RegWrite  = 1'b1;
            ImmSrc    = 2'b00;
            ALUSrc    = 1'b1;
            MemWrite  = 1'b0;
            ResultSrc = 2'b00;
            Branch    = 1'b0;
            ALUOp     = 2'b10;
            Jump      = 1'b0;
        end
        OPC_JAL    : begin 
            RegWrite  = 1'b1;
            ALUSrc    = 1'b0;
            ImmSrc    = 2'b11;
            MemWrite  = 1'b0;
            ResultSrc = 2'b10;
            Branch    = 1'b0;
            ALUOp     = 2'b00;
            Jump      = 1'b1;
        end
        default: begin
            RegWrite  = 1'b0;
            ImmSrc    = 2'b00;
            ALUSrc    = 1'b0;
            MemWrite  = 1'b0;
            ResultSrc = 2'b00;
            Branch    = 1'b0;
            ALUOp     = 2'b00;
            Jump      = 1'b0;
        end
    endcase
    
    // Lógica de BRANCH y JUMP //
    unique case (funct3)
        3'b000: PCSrc = (Branch &  Zero) | Jump;   // BEQ o JAL
        3'b001: PCSrc = (Branch & ~Zero) | Jump;   // BNE o JAL
        3'b100: PCSrc = (Branch &  less) | Jump;   // BLT o JAL
        3'b101: PCSrc = (Branch & ~less) | Jump;   // BGE o JAL
        default: PCSrc = Jump;                     // Otros casos solo JAL
    endcase
    end
    
    //------------------------------------------
    //               ALU Decoder 
    //------------------------------------------
    ALUDecoder ALUCTRL ( 
            .ALUOp(ALUOp), 
            .funct3(funct3), 
            .funct7(funct7), 
            .Opcode(opcode),
            .Op(ALUControl)
        );
endmodule

