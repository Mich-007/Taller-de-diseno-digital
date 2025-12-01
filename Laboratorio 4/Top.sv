`timescale 1ns / 1ps

module Top#(
    parameter int XLEN = 32,
    parameter bit Simulacion = 0, 
    parameter int CLK_HZ = Simulacion ? 100_000_000 : 16_000_000,
    parameter int DEBOUNCE_MS  = 10     
    )(
    input  logic         clk_100, reset,
    input  logic [15:0]  SW,
    input  logic [6:0]   SEG,
    output logic [7:0]   AN,
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
    logic               TEMP_done_rdata;       
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
    logic               IorD;           //Mux que indica si Prog_Adress_i´proviene de PC o ALUOut
    logic               IRWrite;        //Escribir en memoria de instrucciones(ROM)
    logic [31:0]        ProgIn_i;       //Instruccion a ejecutar
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
    logic [3:0]         ALUOp;          //Mux que indica la operacion en la ALU
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
            .PCWriteCond(PCWriteCond),  //Cambiar el valor de PC de acuerdo a tipo branch o jal
            .PCWrite    (PCWrite),      //Cambiar el valor de PC
            .PCSource   (PCSource),     //Decide que valor se suma a PC en el mux   
            //=== Memoria de datos ===  
            .MemRead    (MemRead),      //Leer memoria
            .MemWrite   (MemWrite),     //Escribir en memoria

            //=== Registro ===
            .MemtoReg   (MemtoReg),     //Mux que inidica el valor a escribir en registro
            .RegWrite   (RegWrite),     //Escribir en registro
            //=== Memoria de instrucciones(ROM)===  
            .IorD       (IorD),         //Mux que decide si Prog_Adress_i´proviene de PC o ALUOut
            .IRWrite    (IRWrite),      //Escribir en memoria de instrucciones(ROM)       
            //=== ALU === 
            .Zero       (Zero),         //Bandera zero
            .ALUOp      (ALUOp),        //Mux que indica la operacion en la ALU
            .ALUSrcA    (ALUSrcA),      //pulso de selección de dónde proviene el valor de A
            .ALUSrcB    (ALUSrcB),      //pulso de seleccion de donde proviene el valor de B                 
            .LatchAB    (LatchAB),      //Latch de valores A y B
            .ALUOutEn   (ALUOutEn),     //Bandera para activar el latch del valor de ALU
            //=== Innmediato ===  
            .ImmSrc     (ImmSrc)        //Identificar que tipo de instruccion para determinar el inmediato
            );

//-------------------------------------//
//              Datapath               //
//-------------------------------------//   
    datapath #(.XLEN(64), .Simulacion(Simulacion)) 
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
            .PCWriteCond(PCWriteCond),   //Cambiar el valor de PC de acuerdo a tipo branch o jal
            .PCWrite    (PCWrite),       //Cambiar el valor de PC
            .PCSource   (PCSource),      //Decide que valor se suma a PC en el mux     
            //=== Memoria de datos(RAM) ===  
            .DataIn_i   (DataIn_i),     //data de lectura
            .DataAddress_o(DataAddress_o),//direccion de data
            .DataOut_o  (DataOut_o),    //data de escritura
            //=== Memoria de instrucciones(ROM)===  
            .IorD       (IorD),         //Mux que decide si Prog_Adress_i´proviene de PC o ALUOut
            .IRWrite    (IRWrite),      //Escribir en memoria de instrucciones(ROM)
            .ProgIn_i   (ProgIn_i),     //Instruccion a ejecutar
            .ProgAddress_o(ProgAddress_o),// Direccion de instruccion actual 
            //=== Registro=== 
            .MemtoReg   (MemtoReg),     //escoge el valor a escribir en registro            
            .RegWrite   (RegWrite),     //Escribir en registro
            //=== ALU=== 
            .Zero       (Zero),         //Bandera zero
            .ALUOp      (ALUOp),        //pulso de seleccion para el valor de operacion en la ALU
            .ALUSrcA    (ALUSrcA),      //pulso de selección de dónde proviene el valor de A
            .ALUSrcB    (ALUSrcB),      //pulso de seleccion de donde proviene el valor de B
            .LatchAB    (LatchAB),      //Latch de valores A y B
            .ALUOutEn   (ALUOutEn),     //Bandera para activar el latch del valor de ALU
            //=== Innmediato ===
            .ImmSrc     (ImmSrc)        //Identificar que tipo de instruccion para determinar el inmediato

    );
  
//-------------------------------------//
//     Memoria de instrucciones(ROM)   //
//-------------------------------------//   
     ROM 
        ROM_0_0 (         
            .a      ( ProgAddress_o[10:2] ),
            .spo    (ProgIn_i)
    );
    
//-------------------------------------//
//         Memoria de datos RAM        //            
//-------------------------------------//
    RAM 
        RAM_0_0 (
            .a   (RAM_addr[10:2]),   // usa lo necesario, normalmente [9:0] si son 1024 palabras
            .d   (RAM_wdata),
            .clk (clk_10MHz),
            .we  (RAM_we),
            .spo (RAM_rdata)
    );
    
//-------------------------------------//
//           Mapa de Memoria          //
//------------------------------------//   
    MemMap#(.Simulacion(Simulacion)) 
        DMEM(
          .clk              (clk_10MHz), 
          .reset            (rst_sync10),
          
          .DataAddress_o    (DataAddress_o),
          .DataOut_o        (DataOut_o),
          .MemWrite         (MemWrite),
          .DataIn_i         (DataIn_i),
          
          .RAM_we           (RAM_we),
          .RAM_addr         (RAM_addr),
          .RAM_wdata        (RAM_wdata),
          .RAM_rdata        (RAM_rdata),
          
          .SW_rdata         (SW_rdata),
          .LED_wdata        (LED_wdata),
          .LED_we           (LED_we),
          
          .SEG_wdata        (SEG_wdata),
          .SEG_we           (SEG_we),
          
          .TIMER_ctrl_wdata (TIMER_ctrl_wdata),
          .TIMER_ctrl_we    (TIMER_ctrl_we),
          .TIMER_done_rdata (TIMER_done_rdata),
          
          .TEMP_ctrl_wdata  (TEMP_ctrl_wdata),
          .TEMP_ctrl_we     (TEMP_ctrl_we),
          .TEMP_data_rdata  (TEMP_data_rdata)
  );

//-------------------------------------//
//             Perifericos             //
//-------------------------------------//   
    Perifericos#(.Simulacion(Simulacion)) 
        uP(
          .clk              (clk_10MHz), 
          .reset            (rst_sync10),
          
          .SW_rdata         (SW_rdata),
          
          .LED_wdata        (LED_wdata),
          .LED_we           (LED_we)
  );

//-------------------------------------//
//               Sensor                //
//-------------------------------------//
    TempSensor#(.Simulacion(Simulacion)) 
        uTEMP(
            .clk                (clk_10MHz),
            .reset              (rst_sync10),
            
            .TEMP_ctrl_wdata    (TEMP_ctrl_wdata),
            .TEMP_ctrl_we       (TEMP_ctrl_we),
            .TEMP_data_rdata    (TEMP_data_rdata),
            .TEMP_done_rdata    (TEMP_done_rdata),
            
            .XADC_data          (XADC_data),
            .XADC_ready         (XADC_ready)
    );

//-------------------------------------//
//            Temporizador             //
//-------------------------------------//
    Temporizador #(.Simulacion(Simulacion))
        uTIMER(
            .clk                (clk_10MHz),
            .reset              (rst_sync10),
            
            .TIMER_ctrl_wdata   (TIMER_ctrl_wdata),
            .TIMER_ctrl_we      (TIMER_ctrl_we),
            .TIMER_done_rdata   (TIMER_done_rdata)
        );  
        
//-------------------------------------//
//               XADC                  //
//-------------------------------------// 
    xadc_wiz_0 
        uXADC(
            .dclk_in    (clk_10MHz),
            .reset_in   (rst_sync10),
            .daddr_in   (7'h00),
            .den_in     (1'b0),
            .di_in      (16'h0000),
            .dwe_in     (1'b0),
            .do_out     (XADC_data),
            .drdy_out   (XADC_ready),
            .vp_in      (1'b0),
            .vn_in      (1'b0)
    );

//-------------------------------------//
//               Display               //
//-------------------------------------//       
    Display #(.Simulacion(Simulacion))
        uD(
            .clk        (clk_10MHz),
            .reset      (rst_sync10),
            .SEG        (SEG),
            .AN         (AN),
            .SEG_we     (SEG_we),
            .SEG_wdata  (SEG_wdata)
    );
  
//-------------------------------------//
//             Antirrebote             //
//-------------------------------------// 
    Antirrebote_Switch #(
        .Simulacion(Simulacion),
        .CLK_HZ(CLK_HZ), 
        .DEBOUNCE_MS_HW(5)
    )
        uS(
            .clk        (clk_10MHz),
            .reset      (rst_sync10),
            .SW         (SW),
            .sw0_db     (sw0_db),
            .sw_db_d0   (sw_db_d0),
            .sw1_db     (sw1_db),
            .sw_db_d1   (sw_db_d1),
            .sw2_db     (sw2_db),
            .sw_db_d2   (sw_db_d2),
            .sw3_db     (sw3_db),
            .sw_db_d3   (sw_db_d3)
        );  
        
endmodule
