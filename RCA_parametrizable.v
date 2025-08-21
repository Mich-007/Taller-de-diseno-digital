`timescale 1ns / 1ps

module RCA_parametrizable #(
    parameter N = 8  // Tamaño de palabra (por defecto 8 bits)
)(
    input  wire [N-1:0] A, // Primer operando
    input  wire [N-1:0] B, // Segundo operando
    input  wire Cin, // Acarreo inicial
    output wire [N-1:0] Sum, // Suma
    output wire Cout // Acarreo final
);
    wire [N:0] carry;   // Vector de carries intermedios
    assign carry[0] = Cin; // Acarreo inicial
    
    // Generador de sumadores completos de 1 bit
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : Conjunto_de_SUMs_1bit
            SUM_1bit SUM (
                .A(A[i]),
                .B(B[i]),
                .Cin(carry[i]),
                .Sum(Sum[i]),
                .Cout(carry[i+1])
            );
        end
    endgenerate

    assign Cout = carry[N]; // Acarreo final
 endmodule