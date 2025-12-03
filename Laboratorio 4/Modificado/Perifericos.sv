`timescale 1ns / 1ps
module Perifericos#( 
    parameter bit Simulacion = 0
    )(
    input  logic        clk, reset,
    //=== SW === 
    input  logic [1:0]  sw0_db,     // switches despu�s de antirrebote
    input  logic [1:0]  sw1_db,
    input  logic [1:0]  sw2_db,
    input  logic [1:0]  sw3_db,
    output logic [31:0] SW_rdata,   // lo ve el CPU cuando hace lw
    //=== LED === 
    input  logic        LED_we,
    input  logic [31:0] LED_wdata,
    output logic [15:0] LED

);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) LED <= 16'h0000;
        else if (LED_we) LED <= LED_wdata[15:0];
    end
    

    always_comb begin
        SW_rdata = 32'd0;
        SW_rdata[0] = sw0_db;
        SW_rdata[1] = sw1_db;
        SW_rdata[2] = sw2_db;
        SW_rdata[3] = sw3_db;
    end


endmodule
