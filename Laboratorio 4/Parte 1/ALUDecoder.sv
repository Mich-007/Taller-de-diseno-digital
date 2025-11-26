`timescale 1ns/1ps

module ALUDecoder (
   input  logic [1:0] ALUOp,
   input  logic [6:0] Opcode,
   input  logic [2:0] funct3,    // funct3 
   input  logic [6:0] funct7,    // funct7 
   output logic [3:0] Op     // Selector de operacion hacia la ALU
);

   // Codigos para la ALU
   localparam [3:0]
      ADD_CODE          = 4'b0000, // Suma
      SUB_CODE          = 4'b0001, // Resta
      AND_CODE          = 4'b0010, // AND 
      OR_CODE           = 4'b0011, // OR
      SHIFT_LEFT        = 4'b0100, // SHIFT LEFT
      SHIFT_RIGHT       = 4'b0101, // SHIFT RIGHT
      SHIFT_ARITHMETIC  = 4'b0110, // SHIFT signed
      XOR_CODE          = 4'b0111, // XOR
      COMP_CODE         = 4'b1000, // SLT
      COMP_U_CODE       = 4'b1001; // SLTU

   always_comb begin
      case (ALUOp)
         2'b00:  Op = ADD_CODE; //LW,SW
         2'b01: // Branch
         unique case(funct3) 
             3'b000: Op = SUB_CODE;  // BEQ
             3'b001: Op = SUB_CODE;  // BNE
             3'b100: Op = COMP_CODE; // BLT
             3'b101: Op = COMP_CODE; // BGE
             default: Op = SUB_CODE;
         endcase
            
         2'b10: begin                // Para tipo R (Opcode[5]==1) y tipo I (Opcode[5]==0) (usar funct3/funct7)
            unique case (funct3)
               3'b000:  Op = (funct7[5]==1 && Opcode[5]==1) ? SUB_CODE : ADD_CODE;
               3'b001:  Op = SHIFT_LEFT;
               3'b010:  Op = COMP_CODE;
               3'b011:  Op = COMP_U_CODE;
               3'b100:  Op = XOR_CODE;
               3'b101:  Op = (funct7[5]==1) ? SHIFT_ARITHMETIC : SHIFT_RIGHT;
               3'b110:  Op = OR_CODE;  // OR
               3'b111:  Op = AND_CODE; // AND
               default: Op = ADD_CODE;
            endcase
         end
         default:  Op = ADD_CODE;// Por defecto esta en suma.
      endcase
   end
endmodule
