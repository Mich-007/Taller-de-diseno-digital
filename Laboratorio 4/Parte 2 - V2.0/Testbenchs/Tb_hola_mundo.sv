`timescale 1ns/1ps

module Tb_hola_mundo;

  // Señales de reloj y reset
  logic clk;
  logic rst;
  logic locked;

  // Señales del procesador
  logic [31:0] ProgAddress_o;
  logic [31:0] ProgIn_i;
  logic [31:0] DataIn_i;
  logic [31:0] DataAddress_o;
  logic [31:0] DataOut_o;
  logic        we_o;

  // Reloj principal
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Reset global
  initial begin
    rst = 1;
    repeat(5) @(posedge clk);
    rst = 0;
  end

  // Ajuste de dirección RAM
  logic [31:0] ram_addr;
  assign ram_addr = (DataAddress_o - 32'h0000_1000) >> 2;

  // Instancias

  RISCV_Processor #(.XLEN(32)) RISCV_Processor_0 (
    .clk_i(clk),
    .rst_i(rst),
    .ProgAddress_o(ProgAddress_o),
    .ProgIn_i(ProgIn_i),
    .DataIn_i(DataIn_i),
    .DataAddress_o(DataAddress_o),
    .DataOut_o(DataOut_o),
    .we_o(we_o)
  );

  ROM ROM_0 (
    .a({3'b000,ProgAddress_o[31:2]}),
    .spo(ProgIn_i)
  );

  RAM_0 RAM_0_0 (
    .a(ram_addr[31:2]),
    .d(DataOut_o),
    .clk(clk),
    .we(we_o),
    .spo(DataIn_i)
  );

  // Monitoreo básico
   initial begin
        $display("=== INICIO SIMULACION ===");
    
        forever begin
            @(posedge clk);   // esperar flanco
            if (we_o) begin
                $display("%0t -> ASCII = %c (0x%h)", 
                         $time, 
                         DataOut_o[7:0], 
                         DataOut_o[7:0]);
            end
        end
    end

endmodule
