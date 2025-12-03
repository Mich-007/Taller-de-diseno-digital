`timescale 1ns / 1ps
module Mapa #(
    parameter bit Simulacion = 0,
    parameter int RAM_DEPTH = 4096
)(
    input  logic             clk,
    input  logic             reset,
    // desde datapath/control
    input  logic [31:0]      DataAddress_o, // byte address
    input  logic [31:0]      DataOut_o,     // dato a escribir (32-bit)
    input  logic             MemWrite,
    input  logic             MemRead,
    input  logic [1:0]       access_size,   // 2'b10=word, 2'b01=half, 2'b00=byte
    input  logic             access_signed, // para lecturas lb/lh sign extend
    output logic [31:0]      DataIn_i,      // dato leído hacia datapath

    // RAM interface
    output logic             RAM_we,
    output logic [31:0]      RAM_wdata,
    output logic [($clog2(RAM_DEPTH))-1:0] RAM_addr,
    input  logic [31:0]      RAM_rdata,

    // Periféricos MMIO
    input  logic [31:0]      SW_rdata,
    output logic [31:0]      LED_wdata,
    output logic             LED_we,
    output logic [31:0]      SEG_wdata,
    output logic             SEG_we,
    output logic [31:0]      TIMER_ctrl_wdata,
    output logic             TIMER_ctrl_we,
    input  logic [31:0]      TIMER_done_rdata,
    output logic [31:0]      TEMP_ctrl_wdata,
    output logic             TEMP_ctrl_we,
    input  logic [31:0]      TEMP_data_rdata,
    input  logic [31:0]      TEMP_done_rdata
);

    // Memory map base addresses (ajusta si tu documento usa otras)
    localparam logic [31:0] ADDR_SW   = 32'h2000;
    localparam logic [31:0] ADDR_LED  = 32'h2004;
    localparam logic [31:0] ADDR_SEG  = 32'h2008;
    localparam logic [31:0] ADDR_TIMER_CTRL = 32'h2018;
    localparam logic [31:0] ADDR_TIMER_STATUS = 32'h201C;
    localparam logic [31:0] ADDR_TEMP_CTRL = 32'h2030;
    localparam logic [31:0] ADDR_TEMP_DATA = 32'h2034;
    localparam logic [31:0] ADDR_TEMP_STATUS = 32'h2038;
    localparam logic [31:0] ADDR_RAM_BASE = 32'h0000; // RAM mapped from 0x0000

    // internal signals
    logic is_mmio;
    logic [3:0] be;
    logic [($clog2(RAM_DEPTH))-1:0] ram_word_addr;
    logic [31:0] read_data_ram;
    logic [1:0] read_size;
    logic read_signed;

    // default outputs
    assign LED_we = 1'b0;
    assign SEG_we = 1'b0;
    assign TIMER_ctrl_we = 1'b0;
    assign TEMP_ctrl_we = 1'b0;
    assign LED_wdata = 32'h0;
    assign SEG_wdata = 32'h0;
    assign TIMER_ctrl_wdata = 32'h0;
    assign TEMP_ctrl_wdata = 32'h0;

    // compute byte enables from access_size and address alignment
    // be mapping: be[0] -> byte0 (LSB)
    always_comb begin
        be = 4'b0000;
        case (access_size)
            2'b10: be = 4'b1111; // word
            2'b01: begin // halfword
                if (DataAddress_o[1] == 1'b0) be = 4'b0011; else be = 4'b1100;
            end
            2'b00: begin // byte
                case (DataAddress_o[1:0])
                    2'b00: be = 4'b0001;
                    2'b01: be = 4'b0010;
                    2'b10: be = 4'b0100;
                    2'b11: be = 4'b1000;
                endcase
            end
            default: be = 4'b1111;
        endcase
    end

    // RAM address (word index)
    assign ram_word_addr = DataAddress_o[($clog2(RAM_DEPTH)+1):2]; // byte_addr[AW+1:2]

    // route writes and reads
    always_comb begin
        // default: route to RAM
        is_mmio = 1'b0;
        DataIn_i = 32'h0;
        RAM_we = 1'b0;
        RAM_wdata = DataOut_o;
        read_size = access_size;
        read_signed = access_signed;

        // MMIO detection
        unique case (DataAddress_o)
            ADDR_SW: begin
                is_mmio = 1'b1;
                if (MemRead) DataIn_i = SW_rdata;
            end
            ADDR_LED: begin
                is_mmio = 1'b1;
                if (MemWrite) begin
                    LED_we = 1'b1;
                    LED_wdata = DataOut_o;
                end
            end
            ADDR_SEG: begin
                is_mmio = 1'b1;
                if (MemWrite) begin
                    SEG_we = 1'b1;
                    SEG_wdata = DataOut_o;
                end
            end
            ADDR_TIMER_CTRL: begin
                is_mmio = 1'b1;
                if (MemWrite) begin
                    TIMER_ctrl_we = 1'b1;
                    TIMER_ctrl_wdata = DataOut_o;
                end
            end
            ADDR_TIMER_STATUS: begin
                is_mmio = 1'b1;
                if (MemRead) DataIn_i = TIMER_done_rdata;
            end
            ADDR_TEMP_CTRL: begin
                is_mmio = 1'b1;
                if (MemWrite) begin
                    TEMP_ctrl_we = 1'b1;
                    TEMP_ctrl_wdata = DataOut_o;
                end
            end
            ADDR_TEMP_DATA: begin
                is_mmio = 1'b1;
                if (MemRead) DataIn_i = TEMP_data_rdata;
            end
            ADDR_TEMP_STATUS: begin
                is_mmio = 1'b1;
                if (MemRead) DataIn_i = TEMP_done_rdata;
            end
            default: begin
                is_mmio = 1'b0;
            end
        endcase

        // If not MMIO, route to RAM
        if (!is_mmio) begin
            if (MemWrite) begin
                RAM_we = 1'b1;
                RAM_wdata = DataOut_o;
            end
            // DataIn_i will be provided by RAM_rdata (synchronous read)
            DataIn_i = RAM_rdata;
        end
    end

    // connect RAM ports
    assign RAM_addr = ram_word_addr;

endmodule
