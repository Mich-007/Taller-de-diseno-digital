`timescale 1ns/1ps

module tb_RCA;
    // Número de bits
    parameter N = 4;

    logic [N-1:0] A, B;
    logic Cin;
    logic [N-1:0] Sum;
    logic Cout;

    // Instancia del RCA
    RCA_parametrizable #(.N(N)) DUT (
        .A(A),
        .B(B),
        .Cin(Cin),
        .Sum(Sum),
        .Cout(Cout)
    );

    // Probando el RCA
    initial begin
        $monitor("Tiempo %4t|  A: %d |  B: %d  | Cin: %b |  Sum: %d  | Cout: %b", $time, A, B, Cin, Sum, Cout);

        // Caso 1
        A = 4'b0001; B = 4'b0010; Cin = 0;
        #10
        // Caso 2
        A = 4'b0110; B = 4'b0011; Cin = 0;
        #10
        // Caso 3
        A = 4'b1111; B = 4'b0001; Cin = 0;
        #10 
        // Caso 4 con acarreo de entrada
        A = 4'b1010; B = 4'b0101; Cin = 1;
        #10
        // Caso 5: con overflow
        A = 4'b1111; B = 4'b1111; Cin = 1;
        #10
        
        $finish;
    end
endmodule