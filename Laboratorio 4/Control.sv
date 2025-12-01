`timescale 1ns / 1ps
module control_global #(
    parameter bit Simulacion = 0,
    parameter bit USE_RV64 = 1
)(
    input  logic        clk,
    input  logic        reset,
    output logic [3:0]  st_dbg,    //debug de estados para simulacion
    
    //=== Valores de instruccion ===
    input  logic [6:0]  opcode,
    input  logic [2:0]  funct3,
    input  logic [6:0]  funct7,
    
    //=== PC ===
    output logic        PCWriteCond,  //Cambiar el valor de PC de acuerdo a tipo branch o jal
    output logic        PCWrite,      //Cambiar el valor de PC
    output logic [1:0]  PCSource,     //Decide que valor se suma a PC en el mux
    //=== Memoria de instrucciones(ROM)=== 
    output logic        IorD,         //Mux que decide si Prog_Adress_i´proviene de PC o ALUOut
    output logic        IRWrite,      //Escribir en memoria de instrucciones(ROM)
    //=== Memoria de datos ===
    output logic        MemRead,      //Leer memoria
    output logic        MemWrite,     //Escribir en memoria
    //=== Registro === 
    output logic [1:0]  MemtoReg,     //Mux que inidica el valor a escribir en registro
    output logic        RegWrite,     //Escribir en registro
    //=== ALU ===  
    input  logic        Zero,         //Bandera zero
    output logic [1:0]  ALUOp,        //Mux que indica la operacion en la ALU
    output logic [1:0]  ALUSrcA,      //Mux que indica qu valor se usa para A
    output logic [1:0]  ALUSrcB,      //Mux que indica qu valor se usa para B
    output logic        LatchAB,      //Latch de valores A y B
    output logic        ALUOutEn,     //Bandera para activar el latch del valor de ALU
    //=== Innmediato === 
    output logic [2:0]  ImmSrc        //Identificar que tipo de instruccion para determinar el inmediato
);

  // opcodes base
    localparam logic [6:0]
        OPC_RTYPE = 7'b0110011,
        OPC_ITYPE = 7'b0010011,
        OPC_LOAD  = 7'b0000011,
        OPC_STORE = 7'b0100011,
        OPC_BRANCH= 7'b1100011,
        OPC_JAL   = 7'b1101111,
        OPC_JALR  = 7'b1100111,
        OPC_AUIPC = 7'b0010111,
        OPC_LUI   = 7'b0110111;

    typedef enum logic [3:0] {
       S_IF, S_ID,
       S_EX_RI, S_EX_MEMADR,
       S_MEM_RD, S_MEM_WR,
       S_WB_ALU, S_WB_MEM, S_MEM_WAIT,
       S_EX_BRANCH, S_EX_JAL,
       S_EX_AUIPC
    } state_t;

  state_t st, nx;

// registro de estado
    always_ff @(posedge clk or posedge reset)
        if (reset) 
            st <= S_IF; 
        else 
            st <= nx;

 assign st_dbg = state_t'(st);

//valores default
    task automatic dflt();
        begin
            PCWrite     = 0;    PCWriteCond = 0;
            IorD        = 0;    MemRead = 0; MemWrite = 0; IRWrite = 0;
            MemtoReg    = 2'b00;
            PCSource    = 2'b00;
            ALUSrcA     = 0;    ALUSrcB = 2'b00; ALUOp = 2'b00;
            RegWrite    = 0;    LatchAB = 0;     ALUOutEn = 0;
            ImmSrc      = 3'b000;
        end
    endtask
  
    logic beq = (opcode==OPC_BRANCH) && (funct3==3'b000);
    logic bne = (opcode==OPC_BRANCH) && (funct3==3'b001);
    logic take_branch;
    
  //FSM
    always_comb begin
        dflt();
        nx = st;
        unique0 case (st)

            S_IF: begin
                MemRead  = 1; IorD = 0;
                IRWrite  = 1'b1;
                ALUSrcA  = 2'b00; 
                ALUSrcB = 2'b01; 
                ALUOp = 2'b00;
                PCSource = 2'b00; 
                PCWrite = 1'b1;
                nx =  S_ID;
              end


              S_ID: begin
                LatchAB = 1;
                ALUOutEn = 1'b0;
                ALUSrcA = 2'b00;       // PC
                ALUSrcB = 2'b10;       // imm
                ALUOp   = 2'b00;       // suma
                unique case (opcode)
                  // R / I-ALU
                    OPC_RTYPE: begin ImmSrc = 3'b000; nx = S_EX_RI; end
                    OPC_ITYPE: begin ImmSrc = 3'b001; nx = S_EX_RI; end
                  // LOAD / STORE
                    OPC_LOAD : begin ImmSrc = 3'b001; nx = S_EX_MEMADR; end
                    OPC_STORE: begin ImmSrc = 3'b010; nx = S_EX_MEMADR; end
                  // BRANCH
                    OPC_BRANCH: begin
                        ImmSrc   = 3'b011;
                        ALUSrcA  = 2'b10; 
                        ALUSrcB=2'b10; 
                        ALUOp = 2'b00; 
                        ALUOutEn = 1'b1;       // guarda PC+imm en ALUOut para el próximo ciclo (S_EX_BRANCH)
                        nx       = S_EX_BRANCH;
                    end

                  // JAL: igual, PC <- PC+imm en el siguiente estado, link = PC+4
                    OPC_JAL: begin
                        ImmSrc   = 3'b101;
                        ALUSrcA  = 2'b10; 
                        ALUSrcB  = 2'b10; 
                        ALUOp    = 2'b00;
                        ALUOutEn = 1'b1;
                        nx       = S_EX_JAL;
                    end

                  // AUIPC
                    OPC_AUIPC: begin
                        ImmSrc   = 3'b100;
                        nx       = S_EX_AUIPC;
                    end
                    default: nx = S_IF;
                endcase
              end

              // R / I-ALU: resultado a ALUOut y WB
              S_EX_RI: begin
                ALUSrcA = 2'b01;                                // rs1
                ALUSrcB = (opcode==OPC_ITYPE) ? 2'b10 : 2'b00;  // imm o rs2
                ALUOp   = 2'b10;                                // usar funct3/funct7
                ImmSrc  = (opcode==OPC_ITYPE) ? 3'b001 : 3'b000;
                ALUOutEn = 1;                       // captura resultado en ALUOut
                nx = S_WB_ALU;
              end

         // dirección efectiva = rs1 + imm  (para LOAD/STORE)
              S_EX_MEMADR: begin
                ALUSrcA = 2'b01; ALUSrcB = 2'b10; ALUOp = 2'b00; // suma
                ImmSrc  = (opcode==OPC_LOAD) ? 3'b001 : 3'b010; // I vs S
                ALUOutEn = 1;                                   // ALUOut = EA
                nx = (opcode==OPC_LOAD) ? S_MEM_RD : S_MEM_WR;
              end

        // lectura de datos
              S_MEM_RD: begin
                MemRead = 1; IorD = 1;
                nx = S_MEM_WAIT;
              end
        
              S_MEM_WAIT: begin
                MemRead = 1; IorD = 1;
                nx =  S_WB_MEM;
              end
        
        // escritura de datos
              S_MEM_WR: begin
                MemWrite = 1; IorD = 1;
                nx = S_IF;
              end
        
        // writeback desde ALU (R/I/AUIPC canalizado por aquí)
              S_WB_ALU: begin
                RegWrite = 1; MemtoReg = 2'b00;     // desde ALUOut
                nx = S_IF;
              end
        
        // writeback desde memoria
              S_WB_MEM: begin
                RegWrite = 1; 
                MemtoReg = 2'b01;     // desde Mem
                nx = S_IF;
              end
        
            S_EX_BRANCH: begin
              ALUSrcA = 1'b01;          // rs1
              ALUSrcB = 2'b00;         // rs2
              ALUOp   = 2'b01;         // modo "branch" (la ALU saca Zero)
              PCSource = 2'b01;    
              PCWrite = 1'b0;
              PCWriteCond = 1'b1;
              nx = S_IF;
              end
        
        // JAL: PC <- ALUOut (PC+imm) ; rd <- PC+4
              S_EX_JAL: begin
                PCSource = 2'b01; 
                PCWrite = 1;      // usa ALUOut precargado
                RegWrite = 1; 
                MemtoReg = 2'b10;     // link = PC+4
                ImmSrc   = 3'b101;
                nx = S_IF;
              end
        
        // AUIPC: rd <- PC + imm (lo calculamos aquí y pasamos por WB_ALU)
              S_EX_AUIPC: begin
                ALUSrcA  = 2'b00; 
                ALUSrcB = 2'b10; 
                ALUOp = 2'b00;  // PC + imm
                ALUOutEn = 1;                                  // guardar PC+imm
                RegWrite = 1; 
                MemtoReg = 2'b00;               // WB desde ALUOut
                nx = S_WB_ALU;
              end
        
              default: begin
                dflt();
                nx = S_IF;
              end
        endcase
    end

endmodule

