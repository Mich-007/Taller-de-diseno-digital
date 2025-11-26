`timescale 1ns/1ps
module ALU#(parameter XLEN=64) (
   input    logic   [3:0] ALUControl,           // Selector de Operacion
   input    logic   [XLEN-1:0] A,       // Primer Operando
   input    logic   [XLEN-1:0] B,       // Segundo Operando
   output   logic   [XLEN-1:0] ALUOut,  // Salida de ALU
   output   logic   Zero,               // Bandera de zero
   output   logic   less
);
   // Operaciones de ALU
   localparam [3:0] 
      ADD_CODE          = 4'b0000, // Suma
      SUB_CODE          = 4'b0001, // Resta
      AND_CODE          = 4'b0010, // AND
      OR_CODE           = 4'b0011, // OR
      XOR_CODE          = 4'b0100, // XOR
      COMP_CODE         = 4'b0101, // SLT
      SHIFT_RIGHT       = 4'b0110, // SRL
      SHIFT_ARITHMETIC  = 4'b0111, // SRA
      SHIFT_LEFT        = 4'b1000, // SLL
      COMP_U_CODE       = 4'b1001; // SLTU
      
   always_comb begin
        case (ALUControl)
            ADD_CODE:          ALUOut = A + B;
            SUB_CODE:          ALUOut = A - B;
            AND_CODE:          ALUOut = A & B;
            OR_CODE:           ALUOut = A | B; 
            SHIFT_LEFT:        ALUOut = A << B[$clog2(XLEN)-1:0];
            SHIFT_RIGHT:       ALUOut = A >> B[$clog2(XLEN)-1:0];
            SHIFT_ARITHMETIC:  ALUOut = $signed(A) >>> B[$clog2(XLEN)-1:0];
            XOR_CODE:          ALUOut = A ^ B; 
            COMP_CODE:         ALUOut = ($signed(A) < $signed(B)) ? 1 : 0;
            COMP_U_CODE:       ALUOut = (A < B) ? 1 : 0;
            default:           ALUOut = '0; 
        endcase
    
        Zero = (ALUOut == '0);
    
        // Señal less corregida:
        if (ALUControl == COMP_CODE)
            less = ($signed(A) < $signed(B));
        else
            less = (A < B);
    end
endmodule
