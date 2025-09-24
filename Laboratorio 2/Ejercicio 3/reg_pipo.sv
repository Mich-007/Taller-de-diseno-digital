// reg_pipo.sv
`timescale 1ns/1ps
module reg_pipo #(
    parameter int WIDTH = 16
)(
    input  logic                 clk,
    input  logic                 rst,  // activo alto, asíncrono
    input  logic                 we,
    input  logic [WIDTH-1:0]     d,
    output logic [WIDTH-1:0]     q
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst)      q <= '0;
        else if (we)  q <= d;
    end
endmodule
