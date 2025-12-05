`timescale 1ns / 1ps

module Top (
    input clk, rst,
    input  logic [15:0]  SW,
    output logic [6:0]   SEG,
    output logic [7:0]   AN,
    output logic [15:0]  LED,
    
    output logic         SCL,
    inout  tri           SDA
    );
    
    logic clk_i, rst_i;
    
    logic [31:0] ProgAddress_o, ProgIn_i;            // Señales de ROM
    logic [31:0] DataIn_i, DataAddress_o, DataOut_o; // Señales de RAM
    logic we_o;
    logic locked;
    
    assign rst_i = rst | ~locked;
    
    //-------------------------------------//
    //           Microcontrolador          //
    //-------------------------------------//
    
    RISCV_Processor #(.XLEN(32)) RISCV_Processor_0 (
        .clk_i(clk_i), 
        .rst_i(rst_i),
        .ProgAddress_o(ProgAddress_o),
        .ProgIn_i(ProgIn_i),              
        .DataIn_i(DataIn_i),     
        .DataAddress_o(DataAddress_o),
        .DataOut_o(DataOut_o),    
        .we_o(we_o)
    );
    
    //-------------------------------------//
    //    Memoria de instrucciones ROM     //
    //-------------------------------------//
           
    ROM ROM_0_0 (         
        .a(ProgAddress_o[10:2]),
        .spo(ProgIn_i)
    );
    
    //-------------------------------------//
    //         Memoria de datos RAM        //            
    //-------------------------------------//
    
    // Dirección ajustada para RAM word-addressable
    logic [31:0] ram_addr;
    logic [31:0] RAM_addr;
    logic        RAM_we;
    logic [31:0]  RAM_wdata        ;       
    logic [31:0]  RAM_rdata        ;

    assign ram_addr = (RAM_addr - 32'h0000_1000) >> 2;
    
    RAM_0 RAM_0_0 (
        .a   ({3'b000,ram_addr[9:2]}),   // usa lo necesario, normalmente [9:0] si son 1024 palabras
        .d   (RAM_wdata),
        .clk (clk_i),
        .we  (RAM_we),
        .spo (RAM_rdata)
    );
    
    // PLL //
    PLL_0 PLL_0_0 (
      .clk_out1(clk_i),
      .reset(rst), 
      .locked(locked),
      .clk_in1(clk)
    );
     //-------------------------------------//
     //              BUS GLOBAL             //
     //-------------------------------------//            

     logic [31:0]  LED_wdata        ;       
     logic         LED_we           ;          

     logic [31:0]  SEG_wdata        ;       
     logic         SEG_we           ;          

     logic [31:0]  TIMER_ctrl_wdata ;
     logic         TIMER_ctrl_we    ;   
     logic [31:0]  TIMER_done_rdata ;

     logic [31:0]  TEMP_ctrl_wdata  ; 
     logic         TEMP_ctrl_we     ;    
     logic [31:0]  TEMP_data_rdata  ;
     logic         TEMP_done_rdata;
     
     MemMap MEM1 (
        //=== Memoria de datos (RAM) === 
        .DataAddress_o(DataAddress_o),
        .DataOut_o(DataOut_o),
        .MemWrite(we_o),
        .DataIn_i(DataIn_i),
   
        .RAM_we(RAM_we),
        .RAM_addr(RAM_addr),
        .RAM_wdata(RAM_wdata),
        .RAM_rdata(RAM_rdata),
    
        //=== Periféricos === 
        .SW_rdata(SW),
       
        .LED_wdata(LED_wdata),
        .LED_we(LED_we),
   
        .SEG_wdata(SEG_wdata),
        .SEG_we(SEG_we),
   
        .TIMER_ctrl_wdata(TIMER_ctrl_wdata),
        .TIMER_ctrl_we(TIMER_ctrl_we),
        .TIMER_done_rdata(TIMER_done_rdata),
   
        .TEMP_ctrl_wdata(TEMP_ctrl_wdata),
        .TEMP_ctrl_we(TEMP_ctrl_we),
        .TEMP_data_rdata(TEMP_data_rdata),
        .TEMP_done_rdata(TEMP_done_rdata)
    );
     
     //-------------------------------------//   
     //          TIMER (EN ESPERA...)       // 
     //-------------------------------------//
     
     Temporizador #(.Simulacion(0))
         TIMER_0 (
             .clk                (clk_i),
             .reset              (rst_i),
             
             .TIMER_ctrl_wdata   (TIMER_ctrl_wdata),
             .TIMER_ctrl_we      (TIMER_ctrl_we),
             .TIMER_done_rdata   (TIMER_done_rdata)
     ); 
     
     //-------------------------------------//
     //       SENSOR TMP (EN ESPERA...)     //
     //-------------------------------------//
     
     logic i2c_start;
     logic i2c_busy;
     logic i2c_done;
     logic i2c_err;
     
     TempSensor#(.Simulacion(0)) 
         uTEMP(
             .clk                (clk_i),
             .reset              (rst_i),
             
             .TEMP_ctrl_wdata    (TEMP_ctrl_wdata),
             .TEMP_ctrl_we       (TEMP_ctrl_we),
             .TEMP_data_rdata    (TEMP_data_rdata),
             .TEMP_done_rdata    (TEMP_done_rdata),
             
             .scl                (SCL),
             .sda                (SDA),
             .i2c_start(i2c_start),
             .i2c_busy(i2c_busy),
             .i2c_done(i2c_done),
             .i2c_err(i2c_err)
     );
     
     //-------------------------------------// 
     //               Display               // 
     //-------------------------------------// 
     
     Display Display_0 (
             .clk        (clk_i),
             .seg        (SEG),
             .an         (AN),
             .enable     (SEG_we),
             .data  (SEG_wdata[7:0])
     );
     
     //-------------------------------------// 
     //                 LEDS                //
     //-------------------------------------// 
     
     always_ff @(posedge clk_i or posedge rst_i) begin
        if (rst_i) LED <= 16'h0000;
        else if (LED_we) LED <= LED_wdata[15:0];
     end
endmodule
