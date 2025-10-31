`timescale 1ns / 1ps

module TOP_FIFO_v2(
    input logic clk,
    input logic rst,
    input logic rd,
    input logic wr,
    input logic [7:0] data_in,
    output logic full,
    output logic empty,
    output logic locked,
    output logic [3:0] data_count_0,
    output logic [7:0] disp_an_o,
    output logic [7:0] disp_seg_o
);
wire [7:0] data_out;
logic rd_en,wr_en;

    Pulso_boton btn_rd (
        .clk(clk_16MHz),
        .rst(rst),
        .btn_in(rd),
        .pulso(rd_en)
    );
    Pulso_boton btn_wr (
        .clk(clk_16MHz),
        .rst(rst),
        .btn_in(wr),
        .pulso(wr_en)
    );
    
    FIFO_Block_v2 uut (
        .clk(clk),
        .clk_16MHz(clk_16MHz),
        .rst(rst),
        .rd_en(rd_en),
        .wr_en(wr_en),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty),
        .locked(locked),
        .data_count_0(data_count_0)
    );

// Instancia de Displays de 7 segmentos //
    Display_7seg_32bits Disp1 (
        .clk(clk),
        .data({data_count_0,4'h0,data_in,8'h00,data_out}),
        .enable(1'b1),
        .an(disp_an_o),
        .seg(disp_seg_o)
    );
endmodule
