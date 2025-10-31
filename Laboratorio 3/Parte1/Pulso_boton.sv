`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.10.2025 20:37:45
// Design Name: 
// Module Name: Pulso_boton
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Pulso_boton(
    input logic clk,
    input logic rst,
    input logic btn_in,
    output logic pulso
    );
    logic btn_sync_0, btn_sync_1;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_sync_0 <= 0;
            btn_sync_1 <= 0;
        end else begin
            btn_sync_0 <= btn_in;
            btn_sync_1 <= btn_sync_0;
        end
    end
    assign pulso = (btn_sync_0 && !btn_sync_1);
endmodule
