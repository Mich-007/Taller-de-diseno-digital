// tb_Top.sv
`timescale 1ns/1ps
module tb_Top;
    // Señales
    logic        clk_100;
    logic        reset;
    logic [15:0] SW;
    logic [3:0]  BTN;
    logic [15:0] LED;
    logic [7:0]  AN;
    logic [7:0]  SEG;

    // DUT (MAX_COUNT reducido para acelerar simulación)
    Top #(.MAX_COUNT(20)) dut (
        .clk_100 (clk_100),
        .reset   (reset),
        .SW      (SW),
        .BTN     (BTN),
        .LED     (LED),
        .AN      (AN),
        .SEG     (SEG)
    );

    // Reloj de 100 MHz (10 ns)
    initial clk_100 = 1'b0;
    always #5 clk_100 = ~clk_100;

    // Estímulos
    initial begin
        // Init
        reset = 1'b1;
        SW    = 16'h0000;
        BTN   = 4'h0;
        repeat (5) @(posedge clk_100);
        reset = 1'b0;

        // Habilitar escritura desde el LFSR
        #(200);
        SW[0] = 1'b1;

        // Correr unos cuantos ticks
        #(5000);

        // Deshabilitar
        SW[0] = 1'b0;
        #(1000);

        $finish;
    end

    // Monitor
    always @(posedge clk_100) begin
        $display("[%0t] AN=%b SEG=%b LED=%h digit=%h",
                 $time, AN, SEG, LED, dut.digit);
    end
endmodule
