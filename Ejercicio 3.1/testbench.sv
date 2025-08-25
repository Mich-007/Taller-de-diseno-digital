`timescale 1ns/1ps

module testbench_FPGA_led;

  // Señales de prueba
  logic [15:0] sw;
  logic [3:0]  btn;
  wire  [15:0] led;

  // Instancia del DUT (Device Under Test)
  FPGA_led_switch dut (
    .sw(sw),
    .btn(btn),
    .led(led)
  );

  // ---------------------------
  // TASK para imprimir resultados
  // ---------------------------
  task show_state(input string desc);
    $display("| %0t | %4b | %h | %h | %h | %h | %h | %h | %h | %h | %s |",
       $time, btn,
       sw[15:12], sw[11:8], sw[7:4], sw[3:0],
       led[15:12], led[11:8], led[7:4], led[3:0],
       desc
    );
  endtask

  // ---------------------------
  // TESTBENCH PRINCIPAL
  // ---------------------------
  initial begin 
    $dumpfile("testbench_FPGA_led.vcd");
    $dumpvars(0, testbench_FPGA_led);

    $display("=================================================================================================================");
    $display("                                                TESTBENCH FPGA_led_switch                                        ");
    $display("=================================================================================================================");
    $display("| Time | BTN  |  SW[15:12] | SW[11:8] | SW[7:4] | SW[3:0] | LED[15:12] | LED[11:8] | LED[7:4] | LED[3:0] | Desc |");
    $display("-----------------------------------------------------------------------------------------------------------------");

    // Caso 1: switches todos encendidos
    sw  = 16'hFFFF; btn = 4'b0000; #10; show_state("Todos encendidos, sin botones");

    // Caso 2: apagar grupo 0
    btn = 4'b0001; #10; show_state("Apagar grupo 0");

    // Caso 3: apagar grupo 2
    btn = 4'b0100; #10; show_state("Apagar grupo 2");

    // Caso 4: apagar grupo 1
    btn = 4'b0010; #10; show_state("Apagar grupo 1");

    // Caso 5: apagar grupo 3
    btn = 4'b1000; #10; show_state("Apagar grupo 3");

    // Caso 6: apagar grupos 0 y 2
    btn = 4'b0101; #10; show_state("Apagar grupos 0 y 2");

    // Caso 6: apagar grupos 0 y 2
    btn = 4'b1101; #10; show_state("Apagar grupos 0, 2 y 3");

    // Caso 6: apagar grupos 0 y 2
    btn = 4'b1111; #10; show_state("Apagar grupos 0, 1, 2 y 3");

    // Caso 7: switches patrón A5A5
    sw  = 16'hA5A5; btn = 4'b0000; #10; show_state("Patron A5A5");

    // Caso 7: switches patrón A5A5
    sw  = 16'H0F0F; btn = 4'b0000; #10; show_state("Patrón 0F0F");

    // Caso 7: switches patrón A5A5
    sw  = 16'hC3C3; btn = 4'b0000; #10; show_state("Patrón C3C3");

    // Caso 8: switches patrón 0F0F con grupo 1 apagado
    sw  = 16'hF0F0; btn = 4'b0010; #10; show_state("Patrón F0F0 con grupo1 off");

    // Caso 9: switches patrón AAAA con grupo 3 apagado
    sw  = 16'hAAAA; btn = 4'b1000; #10; show_state("Patrón AAAA con grupo3 off");

    $display("=================================================================================================================");
    $display("                                             FIN DE TESTBENCH                                                    ");
    $display("=================================================================================================================");
    #10 $finish;
  end

endmodule

    
