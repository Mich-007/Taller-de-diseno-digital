`timescale 1ns / 1ps
module ram #(
  parameter int DEPTH = 4096,            // palabras de 32-bit (ajusta si quieres)
  parameter int AW = $clog2(DEPTH),
  parameter int DW = 32
)(
  input  logic             clk,
  input  logic             we,           // write enable (word write when be=4'b1111)
  input  logic [3:0]       be,           // byte enables: be[0] -> byte 0 (LSB)
  input  logic [AW-1:0]    addr,         // word address (addr = byte_addr[AW+1:2])
  input  logic [DW-1:0]    din,
  output logic [DW-1:0]    dout,
  // support for byte/halfword load sign extension
  input  logic             read_signed,  // 0 = unsigned, 1 = signed (used by MemMap)
  input  logic [1:0]       read_size     // 2'b10=word, 2'b01=halfword, 2'b00=byte
);

  logic [7:0] mem_byte [0:DEPTH*4-1]; // byte-addressable memory
  logic [DW-1:0] dout_reg;
  integer i;

  // initialize memory to zero for simulation
  initial begin
    for (i = 0; i < DEPTH*4; i = i + 1) mem_byte[i] = 8'h00;
  end

  // write (byte enables) and synchronous read
  always_ff @(posedge clk) begin
    // write bytes if we asserted
    if (we) begin
      if (be[0]) mem_byte[{addr,2'b00}] <= din[7:0];
      if (be[1]) mem_byte[{addr,2'b01}] <= din[15:8];
      if (be[2]) mem_byte[{addr,2'b10}] <= din[23:16];
      if (be[3]) mem_byte[{addr,2'b11}] <= din[31:24];
    end
    // synchronous read: assemble word from bytes
    dout_reg[7:0]   <= mem_byte[{addr,2'b00}];
    dout_reg[15:8]  <= mem_byte[{addr,2'b01}];
    dout_reg[23:16] <= mem_byte[{addr,2'b10}];
    dout_reg[31:24] <= mem_byte[{addr,2'b11}];
  end

  // output logic with sign/zero extension for byte/halfword loads
  always_comb begin
    case (read_size)
      2'b10: dout = dout_reg; // word
      2'b01: begin // halfword (bits[15:0])
        if (read_signed) begin
          // sign extend 16->32
          dout = {{16{dout_reg[15]}}, dout_reg[15:0]};
        end else begin
          dout = {16'b0, dout_reg[15:0]};
        end
      end
      2'b00: begin // byte (bits[7:0])
        if (read_signed) begin
          dout = {{24{dout_reg[7]}}, dout_reg[7:0]};
        end else begin
          dout = {24'b0, dout_reg[7:0]};
        end
      end
      default: dout = dout_reg;
    endcase
  end

endmodule
