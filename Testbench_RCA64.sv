`timescale 1ns/1ps

module tb_RCA64;
    logic clk;
    logic [63:0] A, B;
    logic Cin;
    logic [63:0] Sum;
    logic Cout;

    // Instancia del CLA
    RCA_parametrizable #(.N(64)) DUT (
        .A(A),
        .B(B),
        .Cin(Cin),
        .Sum(Sum),
        .Cout(Cout)
    );

    // Generación de reloj de 10 MHz
    initial clk = 0;
    always #50 clk = ~clk;

    initial begin
        $monitor("%t: A=%h B=%h Cin=%b -> Sum=%h Cout=%b", $time, A, B, Cin, Sum, Cout);
        // Generador de datos a 100 MS/s (10 ns entre cada cambio que hace)
        A = 0; B = 0; Cin = 0;
        #5;

        forever begin
            #10;
            A = $random;
            B = $random;
            Cin = $random % 2;
        end
        #100 $finish;
    end
endmodule