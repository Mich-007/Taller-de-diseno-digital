`timescale 1ns / 1ps
module datapath #(
    parameter int XLEN = 32,
    parameter bit Simulacion = 0
    )(
        input  logic             clk, reset,
        //=== Valores de instruccion ===  
        output logic [6:0]       opcode,
        output logic [2:0]       funct3,
        output logic [6:0]       funct7,
        output logic [4:0]       rs1,
        output logic [4:0]       rs2,
        output logic [4:0]       rd,       
    //=== PC === 
        input  logic             PCWrite,       
        input  logic             PCWriteCond,   
        input  logic [1:0]       PCSource,      
        
    //=== Memoria de datos ===  
        input  logic [XLEN-1:0]  DataIn_i,     
        output logic [XLEN-1:0]  DataAddress_o, 
        output logic [XLEN-1:0]  DataOut_o,    
    
    //=== Memoria de instrucciones === 
        input  logic             IorD,          
        input  logic             IRWrite,       
        input logic [31:0]       ProgIn_i,      // instrucción desde ROM (síncrona)
        output logic [XLEN-1:0]  ProgAddress_o, 
                   
    //=== Registro ===
        input  logic [1:0]       MemtoReg,      
        input  logic             RegWrite,      
    //=== ALU ===  
        input  logic [1:0]       ALUOp,         
        input  logic [1:0]       ALUSrcA,       
        input  logic [1:0]       ALUSrcB,       
        input  logic             LatchAB,       
        input  logic             ALUOutEn,      
        output logic             Zero,          
    //=== Innmediato ===   
        input  logic [2:0]       ImmSrc         
);
    
 //________________________________________________________________________
 // Instruction Register (IR) - captura la salida de la ROM/IP
 //
    logic [31:0] IR;
    always_ff @(posedge clk or posedge reset) begin
      if (reset) IR <= 32'b0;
      else if (IRWrite) IR <= ProgIn_i;
    end

 //________________________________________________________________________
 //                             Inmediato
 //
    logic [XLEN-1:0] Imm;
    immgen #(.XLEN(XLEN)) 
        IMMGEN (
            .instr_d    (IR), 
            .ImmSrc     (ImmSrc), 
            .imm        (Imm));
    
 //________________________________________________________________________
 //                             Registro
 // 

    // Campos desde IR (usar IR en lugar de ProgIn_i)
    assign opcode = IR[6:0]; 
    assign funct3 = IR[14:12];
    assign funct7 = IR[31:25];
    
    assign rs1 =    IR[19:15];
    assign rs2 =    IR[24:20];
    assign rd  =    IR[11:7];   
    
logic [XLEN-1:0] read_data1, read_data2, write_data;
    
    register_file #(.DATA_WIDTH(XLEN)) RF 
        (
            .clk(clk), 
            .reset(reset), 
            .RegWrite(RegWrite),
            .rs1(rs1), 
            .rs2(rs2), 
            .rd(rd),
            .write_data(write_data), 
            .read_data1(read_data1), 
            .read_data2(read_data2)
    );
   
// ________________________________________________________________________
//                          ALU datapath
// 
    logic [XLEN-1:0] A, B, ALUOut;
    logic [XLEN-1:0] srcA;
    logic [XLEN-1:0] srcB; 
    logic [XLEN-1:0] ALUResult;
    logic [1:0]      Op;
    
    ALU_Control 
        ALUCTRL( 
            .ALUOp(ALUOp), 
            .funct3(funct3), 
            .funct7(funct7), 
            .Op(Op)
    );
            
    ALU #(.XLEN(XLEN)) 
        ALU(
            .A      (srcA), 
            .B      (srcB), 
            .Op     (Op), 
            .ALUOut (ALUResult), 
            .Zero   (Zero)
     );
        
    always_ff @(posedge clk or posedge reset) begin
      if (reset) 
        ALUOut <= '0;
      else 
      if (ALUOutEn) //Si la ALU se activa
        ALUOut <= ALUResult;
    end  
    
    always_ff @(posedge clk) begin
        if (reset) begin 
            A <= '0; 
            B <= '0; 
        end else 
        if (LatchAB) begin 
            A <= read_data1;
            B <= read_data2; 
        end
    end

// ________________________________________________________________________
//                              Multiplexores
//   
logic [XLEN-1:0] PC, PC_next;
     
    always_comb begin
      // MUX de A
      unique case (ALUSrcA)  
        2'b00: srcA = PC;
        2'b01: srcA = A;       
        2'b10: srcA = ProgAddress_o;    
        default: srcA = PC;
      endcase
      // MUX de B
      unique case (ALUSrcB) 
        2'b00: srcB = B;
        2'b01: srcB = XLEN'(4);
        2'b10: srcB = Imm;
        default: srcB = B;    
      endcase
    end

logic [XLEN-1:0] PC4;
assign PC4 = PC + XLEN'(4); 

//MemtoReg
    always_comb begin
      unique case (MemtoReg)  //Indicar el valor que se escribe en el registro
        2'b00: write_data = ALUOut;
        2'b01: write_data = DataIn_i;
        2'b10: write_data = PC4;
        default: write_data = ALUOut;  
      endcase
    end
    
//Branch y slt cond
    logic BrCondMet;
    // Nota: lógica de condiciones más completa se implementará en Bloque B.
    always_comb unique case (funct3)
        3'b000: BrCondMet =  (Zero); //beq
        3'b001: BrCondMet = !(Zero); //bne
        default: BrCondMet = 1'b0;
    endcase

//PCSourse
    always_comb unique case (PCSource)  //Indicar de donde proviene la direccion de PC
      2'b00: PC_next = PC4; //R-type, I_Type                 
      2'b01: PC_next = ALUOut; //Branch / JAL target               
      2'b10: PC_next = {ALUResult[XLEN-1:1],1'b0};  // JALR target (rs1+imm) masked
      default: PC_next = PC4;
    endcase
    
//Valor actualizado de PC   
    wire pc_en = PCWrite | (PCWriteCond & BrCondMet);  
    always_ff @(posedge clk or posedge reset) begin
      if (reset) PC <= '0;
      else if (pc_en) PC <= PC_next;
    end
 
assign ProgAddress_o = PC;
    
 // Direcciones a memorias
logic [XLEN-1:0] Addr;

assign Addr = (IorD == 1'b0) ? PC : ALUOut;
    
assign DataAddress_o = Addr;
assign DataOut_o = B;

endmodule
