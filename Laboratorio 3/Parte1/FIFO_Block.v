//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
//Date        : Thu Oct 16 09:13:26 2025
//Host        : DESKTOP-TFLSP52 running 64-bit major release  (build 9200)
//Command     : generate_target FIFO_Block.bd
//Design      : FIFO_Block
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "FIFO_Block,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=FIFO_Block,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=2,numReposBlks=2,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,da_board_cnt=1,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "FIFO_Block.hwdef" *) 
module FIFO_Block
   (clk,
    clk_16MHz,
    data_count_0,
    data_in,
    data_out,
    empty,
    full,
    locked,
    rd_en,
    rst,
    wr_en);
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CLK, CLK_DOMAIN FIFO_Block_clk_100MHz, FREQ_HZ 100000000, INSERT_VIP 0, PHASE 0.000" *) input clk;
  output clk_16MHz;
  output [8:0]data_count_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:data:1.0 DATA.DATA_IN DATA" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME DATA.DATA_IN, LAYERED_METADATA undef" *) input [7:0]data_in;
  output [7:0]data_out;
  output empty;
  output full;
  output locked;
  input rd_en;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.RST RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.RST, INSERT_VIP 0, POLARITY ACTIVE_HIGH" *) input rst;
  input wr_en;

  wire Net;
  wire clk_100MHz_1;
  wire clk_wiz_0_clk_out1;
  wire clk_wiz_0_locked;
  wire data_in1_1;
  wire [7:0]data_in_1;
  wire [8:0]fifo_generator_0_data_count;
  wire [7:0]fifo_generator_0_dout;
  wire fifo_generator_0_empty;
  wire fifo_generator_0_full;
  wire wr_en_1;

  assign Net = rst;
  assign clk_100MHz_1 = clk;
  assign clk_16MHz = clk_wiz_0_clk_out1;
  assign data_count_0[8:0] = fifo_generator_0_data_count;
  assign data_in1_1 = rd_en;
  assign data_in_1 = data_in[7:0];
  assign data_out[7:0] = fifo_generator_0_dout;
  assign empty = fifo_generator_0_empty;
  assign full = fifo_generator_0_full;
  assign locked = clk_wiz_0_locked;
  assign wr_en_1 = wr_en;
  FIFO_Block_clk_wiz_0_0 clk_wiz_0
       (.clk_in1(clk_100MHz_1),
        .clk_out1(clk_wiz_0_clk_out1),
        .locked(clk_wiz_0_locked),
        .reset(Net));
  FIFO_Block_fifo_generator_0_0 fifo_generator_0
       (.clk(clk_wiz_0_clk_out1),
        .data_count(fifo_generator_0_data_count),
        .din(data_in_1),
        .dout(fifo_generator_0_dout),
        .empty(fifo_generator_0_empty),
        .full(fifo_generator_0_full),
        .rd_en(data_in1_1),
        .srst(Net),
        .wr_en(wr_en_1));
endmodule
