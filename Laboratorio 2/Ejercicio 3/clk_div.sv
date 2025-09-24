// clk_div.sv
`timescale 1ns/1ps
// Genera un pulso 'tick' de un ciclo cada MAX_COUNT ciclos de 'clk'.
module clk_div #(
    parameter int unsigned MAX_COUNT = 200_000_000
)(
    input  logic clk,
    input  logic rst,
    output logic tick
);
    localparam int NB = $clog2(MAX_COUNT);
    logic [NB-1:0] cnt;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt  <= '0;
            tick <= 1'b0;
        end
        else if (cnt == MAX_COUNT-1) begin
            cnt  <= '0;
            tick <= 1'b1;    // *** Corrección: generar pulso en el recarga ***
        end
        else begin
            cnt  <= cnt + {{NB-1{1'b0}},1'b1};
            tick <= 1'b0;
        end
    end
endmodule
