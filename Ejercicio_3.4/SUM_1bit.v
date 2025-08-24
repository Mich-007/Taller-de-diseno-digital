`timescale 1ns / 1ps

module SUM_1bit(
    input  wire A, // Primer bit de entrada
    input  wire B, // Segundo bit de entrada
    input  wire Cin, // Acarreo de entrada
    output wire Sum, // Suma
    output wire Cout // Acarreo de salida
);
    assign Sum  = A ^ B ^ Cin; // XOR de las entradas
    assign Cout = (A & B) | (A & Cin) | (B & Cin); // Generación de acarreo
endmodule
