`timescale 1ns / 1ps

module Top (
    input clk, rst
    );
    
    logic clk_i, rst_i;
    
    logic [31:0] ProgAddress_o, ProgIn_i;            // Señales de ROM
    logic [31:0] DataIn_i, DataAddress_o, DataOut_o; // Señales de RAM
    logic we_o;
    logic locked;
    
    assign rst_i = rst | ~locked;
    
    //-------------------------------------//
    //           Microprocesador           //
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
        .a({3'b000,ProgAddress_o[31:2]}),
        .spo(ProgIn_i)
    );
    
    //-------------------------------------//
    //         Memoria de datos RAM        //            
    //-------------------------------------//
    
    // Dirección ajustada para RAM word-addressable
    logic [31:0] ram_addr;

    assign ram_addr = (DataAddress_o - 32'h0000_1000) >> 2;
    
    RAM_0 RAM_0_0 (
        .a   (ram_addr[31:0]),   // usa lo necesario, normalmente [9:0] si son 1024 palabras
        .d   (DataOut_o),
        .clk (clk_i),
        .we  (we_o && (DataAddress_o >= 32'h1000 && DataAddress_o <= 32'h1FFF)),
        .spo (DataIn_i)
    );
    
    // PLL //
    PLL_0 PLL_0_0 (
      .clk_out1(clk_i),
      .reset(rst), 
      .locked(locked),
      .clk_in1(clk)
    );
     //-------------------------------------//
     //       BUS GLOBAL (EN ESPERA...)     //
     //-------------------------------------//
     //-------------------------------------//   
     //          TIMER (EN ESPERA...)       // 
     //-------------------------------------//
     //-------------------------------------//
     //       SENSOR TMP (EN ESPERA...)     //
     //-------------------------------------//
endmodule
