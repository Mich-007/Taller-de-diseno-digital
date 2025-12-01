module datapath #(
    parameter int XLEN = 64,
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
        input  logic             PCWrite,       //Cambiar el valor de PC
        input  logic             PCWriteCond,   //Cambiar el valor de PC de acuerdo a tipo branch o jal
        input  logic [1:0]       PCSource,      //Decide que valor se suma a PC en el mux 
        
//=== Memoria de datos ===  
        input  logic [XLEN-1:0]  DataIn_i,     //data de lectura
        output logic [XLEN-1:0]  DataAddress_o, //direccion de data
        output logic [XLEN-1:0]  DataOut_o,    //data de escritura
        
//=== Memoria de instrucciones === 
        input  logic             IorD,          //Mux que decide si Prog_Adress_i´proviene de PC o ALUOut
        input  logic             IRWrite,       //Escribir en memoria de instrucciones(ROM)
        input logic [31:0]       ProgIn_i,      //Instruccion a ejecutar
        output logic [XLEN-1:0]  ProgAddress_o, // Direccion de instruccion actual     
               
//=== Registro ===
        input  logic [1:0]       MemtoReg,      //Mux que inidica el valor a escribir en registro
        input  logic             RegWrite,      //Escribir en registro
//=== ALU ===  
        input  logic [1:0]       ALUOp,         //Operacion que debe realizar la ALU
        input  logic [1:0]       ALUSrcA,       //Mux que indica qu valor se usa para A
        input  logic [1:0]       ALUSrcB,       //Mux que indica que valor se usa para B
        input  logic             LatchAB,       //Latch de valores A y B
        input  logic             ALUOutEn,      //Bandera para activar el latch del valor de ALU
        output logic             Zero,          //Bandera zero
//=== Innmediato ===   
        input  logic [2:0]       ImmSrc         //Identificar que tipo de instruccion para determinar el inmediato
        
);
    
 //-------------------------------------------------------------------
 //                             Inmediato
 //------------------------------------------------------------------- 
    logic [XLEN-1:0] Imm;
    immgen_rv64 #(.XLEN(XLEN)) 
        IMMGEN (
            .instr_d    (ProgIn_i), 
            .ImmSrc     (ImmSrc), 
            .imm        (Imm));
    
 //-------------------------------------------------------------------
 //                             Registro
 //------------------------------------------------------------------- 

    // Campos desde IR
    assign opcode = ProgIn_i[6:0]; 
    assign funct3 = ProgIn_i[14:12];
    assign funct7 = ProgIn_i[31:25];
    
    assign rs1 =    ProgIn_i[19:15];
    assign rs2 =    ProgIn_i[24:20];
    assign rd  =    ProgIn_i[11:7];   
    
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
   
// -------------------------------------------------------------------
//                          ALU datapath
// -------------------------------------------------------------------
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

// -------------------------------------------------------------------
//                              Multiplexores
// -------------------------------------------------------------------  
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
    logic shift;
    always_comb unique case (funct3)
        3'b000: BrCondMet =  (Zero); //bne
        3'b001: BrCondMet = !(Zero); //beq
        3'b010: BrCondMet =  (ALUResult == 64'd1); //slt , slti
        3'b011: BrCondMet =  (ALUResult == 64'd1); //sltu, sltui
        3'b100: BrCondMet =  (ALUResult == 64'd1); // blt
        3'b101: BrCondMet =  (ALUResult == 64'd0); // bge
      default: BrCondMet = 1'b0;
    endcase

//PCSourse
    always_comb unique case (PCSource)  //Indicar de donde proviene la direccion de PC
      2'b00: PC_next = PC4; //R-type, I_Type                 
      2'b01: PC_next = ALUOut; //Branch               
      2'b10: PC_next = {ALUResult[XLEN-1:1],1'b0};  
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

