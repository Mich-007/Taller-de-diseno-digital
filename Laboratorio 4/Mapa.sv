`timescale 1ns / 1ps
module MemMap #(
    parameter int RAM_START = 32'h0000_1000,
    parameter int RAM_END   = 32'h0000_1FFF,
    parameter bit Simulacion = 0 
)(
    input  logic         clk, reset,
    //=== Memoria de datos(RAM) === 
    input  logic [31:0]  DataAddress_o,     //direccion de data
    input  logic [31:0]  DataOut_o,         //data de escritura
    input  logic         MemWrite,          //Escribir en memoria
    output logic [31:0]  DataIn_i,          //data de lectura

    output logic         RAM_we,             //Escribir en RAM    
    output logic [31:0]  RAM_addr,           //Direccion de RAM   
    output logic [31:0]  RAM_wdata,          //Dato a escribir en 
    input  logic [31:0]  RAM_rdata,          //Dato a leer de RAM 

    //=== Perifericos === 
    input  logic [31:0]  SW_rdata,
    
    output logic [31:0]  LED_wdata,
    output logic         LED_we,

    output logic [31:0]  SEG_wdata,
    output logic         SEG_we,

    output logic [31:0]  TIMER_ctrl_wdata,
    output logic         TIMER_ctrl_we,
    input  logic [31:0]  TIMER_done_rdata,

    output logic [31:0]  TEMP_ctrl_wdata,
    output logic         TEMP_ctrl_we,
    input  logic [31:0]  TEMP_data_rdata,
    input logic  [31:0]  TEMP_done_rdata
);

    // ----------------------------
    // Decodificador de Direcciones
    // ----------------------------

    logic RAM_bus, SW_bus, LED_bus, SEG_bus;
    logic TIMER_ctrl, TIMER_done;
    logic TEMP_ctrl, TEMP_data, TEMP_done;
    
    always_comb begin
        RAM_bus     = (DataAddress_o >= RAM_START && DataAddress_o <= RAM_END);
        SW_bus      = (DataAddress_o == 32'h0000_2000);
        LED_bus     = (DataAddress_o == 32'h0000_2004);
        SEG_bus     = (DataAddress_o == 32'h0000_2008);
    
        TIMER_ctrl  = (DataAddress_o == 32'h0000_2018);
        TIMER_done  = (DataAddress_o == 32'h0000_201C);
    
        TEMP_ctrl   = (DataAddress_o == 32'h0000_2030);
        TEMP_data   = (DataAddress_o == 32'h0000_2034);
        TEMP_done   = (DataAddress_o == 32'h0000_2038);
    end

    // ----------------------------
    // Escrituras
    // ----------------------------

    assign RAM_we           = MemWrite && RAM_bus;  //Escribir en la RAM, si cumple estas condiciones
    assign RAM_addr         = DataAddress_o;
    assign RAM_wdata        = DataOut_o;               //Dato a escribir en la RAM

    assign LED_we           = MemWrite && LED_bus; //Escribir en la memoria de los LEDS
    assign LED_wdata        = DataOut_o;
    
    assign SEG_we           = MemWrite && SEG_bus;
    assign SEG_wdata        = DataOut_o;

    assign TIMER_ctrl_we    = MemWrite && TIMER_ctrl;
    assign TIMER_ctrl_wdata = DataOut_o;

    assign TEMP_ctrl_we     = MemWrite && TEMP_ctrl;
    assign TEMP_ctrl_wdata  = DataOut_o;

    // ----------------------------
    // Lecturas
    // ----------------------------

    always_comb begin
        if      (RAM_bus)         DataIn_i = RAM_rdata;
        else if (SW_bus)          DataIn_i = SW_rdata;
        else if (TIMER_done)      DataIn_i = TIMER_done_rdata;
        else if (TEMP_data)       DataIn_i = TEMP_data_rdata;
        else if (TEMP_done)       DataIn_i = TEMP_done_rdata;
        else                      DataIn_i = 32'h0000_0000;
    end

endmodule

