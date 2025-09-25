`timescale 1ns / 1ps

module ClkWiz_testbench;

  // Señales
  logic clk_0;         // reloj de entrada 100 MHz
  logic clk_10Mhz;    // salida esperada de 10 MHz
  logic rst_0;
  logic clk_100Mhz;
  logic locked_0;

  // Instanciamos el DUT (Device Under Test)
  design_1 uut (
    .rst_0(rst_0),
    .clk_0(clk_0),
    .clk_10Mhz(clk_10Mhz),
    .clk_100Mhz(clk_100Mhz),
    .locked_0(locked_0)
  );

  // Generador de reloj 100 MHz (periodo 10 ns)
  initial begin
    clk_0 = 0;
    rst_0 = 1;
    forever #5 clk_0=~clk_0;  // alterna cada 5 ns ? 100 MHz
  end

  // Proceso de simulación
  initial begin
    #5 rst_0 = 0;
    $display("Iniciando simulación...");

    // Simulación durante 2 ms (~20k ciclos de salida a 10 MHz)
    #2000;
    $display("Fin de la simulación.");
    $finish;
  end
endmodule
