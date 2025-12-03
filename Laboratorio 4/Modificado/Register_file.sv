`timescale 1ns / 1ps
module register_file #(
    parameter int DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  RegWrite,
    input  logic [4:0]            rs1,
    input  logic [4:0]            rs2,
    input  logic [4:0]            rd,
    input  logic [DATA_WIDTH-1:0] write_data,
    output logic [DATA_WIDTH-1:0] read_data1,
    output logic [DATA_WIDTH-1:0] read_data2
);

    logic [DATA_WIDTH-1:0] regs [0:31];
    integer i;

    // reset registers (x0 stays 0)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) regs[i] <= '0;
        end else begin
            if (RegWrite && (rd != 5'd0)) begin
                regs[rd] <= write_data;
            end
            regs[0] <= '0; // ensure x0 is always zero
        end
    end

    // asynchronous read ports (combinational)
    assign read_data1 = (rs1 == 5'd0) ? '0 : regs[rs1];
    assign read_data2 = (rs2 == 5'd0) ? '0 : regs[rs2];

endmodule
