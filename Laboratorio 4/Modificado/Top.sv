`timescale 1ns _ 1ps

module Top#(
    parameter int XLEN = 32,
    parameter bit Simulacion = 0, 
    // usar 10 MHz real
    parameter int CLK_HZ = Simulacion ? 1_000_000 : 10_000_000,
    parameter int DEBOUNCE_MS  = 10     
)(
    input  logic         clk_100, reset,
    input  logic [15:0]  SW,
    output logic [6:0]   SEG,    // SEG son salidas
    output logic [7:0]   AN,     // AN son salidas
    output logic [15:0]  LED,
    output logic [3:0]   st_dbg
    );

//=== Perifericos === 
    logic [31:0]        SW_rdata;   
            
    logic [31:0]        LED_wdata;          
    logic               LED_we;             
    
    logic [31:0]        SEG_wdata;          
    logic               SEG_we;             
    
    logic [31:0]        TIMER_ctrl_wdata;   
    logic               TIMER_ctrl_we; 
    logic [31:0]        TIMER_done_rdata;   
    
    logic [31:0]        TEMP_ctrl_wdata;    
    logic               TEMP_ctrl_we;
    logic [31:0]        TEMP_done_rdata;       
    logic [31:0]        TEMP_data_rdata;     
//=== XADC ===
    logic [15:0]        XADC_data;
    logic               XADC_ready;                                      
//=== Antirrebote ===    
    logic               sw0_db; 
    logic               sw_db_d0;
    logic               sw1_db; 
    logic               sw_db_d1;
    logic               sw2_db; 
    logic               sw_db_d2;
    logic               sw3_db; 
    logic               sw_db_d3;
                                       
//=== Valores de instruccion ===  
    logic [6:0]         opcode;
    logic [2:0]         funct3;
    logic [6:0]         funct7;
    logic [4:0]         rs1;
    logic [4:0]         rs2;
    logic [4:0]         rd;  
//=== PC ===  
    logic               PCWriteCond;    //Cambiar el valor de PC de acuerdo a tipo branch o jal
    logic               PCWrite;        //Cambiar el valor de PC
    logic [1:0]         PCSource;
    
//=== Memoria de instrucciones(ROM) === 
    logic               IorD;           //Mux que indica si Prog_Adress_i proviene de PC o ALUOut
    logic               IRWrite;        //Escribir en memoria de instrucciones(ROM)
    logic [31:0]        ProgIn_i;       //Instruccion a ejecutar (salida ROM)
    logic [XLEN-1:0]    ProgAddress_o;
    
//=== Memoria de datos(RAM) === 
    logic               RAM_we;         //Escribir en RAM
    logic [31:0]        RAM_addr;       //Direccion de RAM
    logic [31:0]        RAM_wdata;      //Dato a escribir en RAM
    logic [31:0]        RAM_rdata;      //Dato a leer de RAM
    logic               MemRead;        //Leer memoria
    logic               MemWrite;       //Escribir en memoria
    logic [XLEN-1:0]    DataIn_i;       //data de lectura
    logic [XLEN-1:0]    DataAddress_o;   //direccion de data
    logic [XLEN-1:0]    DataOut_o;      //data de escritura
    
//=== Registro ===    
    logic [1:0]         MemtoReg;       //Mux que indica el valor a escribir en registro
    logic               RegWrite;       //Escribir en registro
    
//=== ALU ===  
    logic [1:0]         ALUOp;          // CORRECCIÓN: 2 bits para coincidir con control_global
    logic [1:0]         ALUSrcB;        //Mux que indica qu valor se usa para B
    logic [1:0]         ALUSrcA;        //Mux que indica que valor se usa para A
    logic               LatchAB;        //Latch de valores A y B
    logic               ALUOutEn;       //Bandera para activar el latch del valor de ALU
    logic               Zero;           //Bandera zero
    
//=== Immediate ===      
    logic [2:0]         ImmSrc;         //Identificar que tipo de instruccion para determinar el inmediato

//===Reloj y reset reales y para simulacion===
    logic clk_10MHz;
    logic locked;
    logic rst_sync10;
    logic clk_10MHz_hw, locked_hw;

// Valores para simulacion
assign clk_10MHz = (Simulacion) ? clk_100  : clk_10MHz_hw;
assign locked    = (Simulacion) ? 1'b1        : locked_hw;
assign rst_sync10= (Simulacion) ? reset       : (reset | ~locked_hw);

//-------------------------------------//
//           Reloj de 10 MHz           //
//-------------------------------------//   
    clk_wiz_0
        u_bd (
            .clk_in1    (clk_100),
            .clk_out1   (clk_10MHz_hw),
            .reset      (rst_sync10), 
            .locked     (locked_hw)
    );   
       
//-------------------------------------//
//          Unidad de Control          //
//-------------------------------------//    
    control_global #(.Simulacion(Simulacion))
        uA (   
            .clk        (clk_10MHz), 
            .reset      (rst_sync10), 
            .st_dbg     (st_dbg),       //debug de estados para simulacion
            //=== Valores de instruccion ===
            .opcode     (opcode), 
            .funct3     (funct3), 
            .funct7     (funct7), 
            //=== PC ===
            .PCWriteCond(PCWriteCond),  
            .PCWrite    (PCWrite),      
            .PCSource   (PCSource),     
            //=== Memoria de datos ===  
            .MemRead    (MemRead),      
            .MemWrite   (MemWrite),     
            //=== Registro ===
            .MemtoReg   (MemtoReg),     
            .RegWrite   (RegWrite),     
            //=== Memoria de instrucciones(ROM)===  
            .IorD       (IorD),         
            .IRWrite    (IRWrite),      
            //=== ALU === 
            .Zero       (Zero),         
            .ALUOp      (ALUOp),        
            .ALUSrcA    (ALUSrcA),      
            .ALUSrcB    (ALUSrcB),                 
            .LatchAB    (LatchAB),      
            .ALUOutEn   (ALUOutEn),     
            //=== Innmediato ===  
            .ImmSrc     (ImmSrc)        
            );

//-------------------------------------//
//              Datapath               //
//-------------------------------------//   
    datapath #(.XLEN(XLEN), .Simulacion(Simulacion)) 
        DP (
            .clk        (clk_10MHz), 
            .reset      (rst_sync10), 
            //=== Valores de instruccion ===
            .opcode     (opcode), 
            .funct3     (funct3), 
            .funct7     (funct7), 
            .rs1        (rs1),
            .rs2        (rs2),
            .rd         (rd),
            //=== PC === 
            .PCWriteCond(PCWriteCond),   
            .PCWrite    (PCWrite),       
            .PCSource   (PCSource),      
            //=== Memoria de datos(RAM) ===  
            .DataIn_i   (DataIn_i),     
            .DataAddress_o(DataAddress_o),
            .DataOut_o  (DataOut_o),    
            //=== Memoria de instrucciones(ROM)===  
            .IorD       (IorD),         
            .IRWrite    (IRWrite),      
            .ProgIn_i   (ProgIn_i),     
            .ProgAddress_o(ProgAddress_o),
            //=== Registro=== 
            .MemtoReg   (MemtoReg),               
            .RegWrite   (RegWrite),     
            //=== ALU=== 
            .Zero       (Zero),         
            .ALUOp      (ALUOp),        
            .ALUSrcA    (ALUSrcA),      
            .ALUSrcB    (ALUSrcB),      
            .LatchAB    (LatchAB),      
            .ALUOutEn   (ALUOutEn),     
            //=== Innmediato ===
            .ImmSrc     (ImmSrc)        
    );
  
//-------------------------------------//
//     Memoria de instrucciones(ROM)   //
//-------------------------------------//   
     ROM 
        ROM_0_0 (         
            .a      ( ProgAddress_o[10:2] ),
            .spo    (ProgIn_i)
    );
    
        
endmodule
