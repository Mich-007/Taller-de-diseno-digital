`timescale 1ns / 1ps


// Modulo de bloque de CLA de 4 bits con lógica para acarreo
module CLABloque (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       Cin,
    output wire [3:0] Sum,
    output wire       Cout,
    output wire       P_s,
    output wire       G_s
);
    wire [3:0] p, g;
    wire c1, c2, c3, c4;

    // P y G por bit
    assign p = A ^ B;
    assign g = A & B;

    // Ecuaciones lookahead de logica del CLA
    assign c1 = g[0] | (p[0] & Cin);
    assign c2 = g[1] | (p[1] & c1);
    assign c3 = g[2] | (p[2] & c2);
    assign c4 = g[3] | (p[3] & c3);

    // Sumas
    assign Sum[0] = p[0] ^ Cin;
    assign Sum[1] = p[1] ^ c1;
    assign Sum[2] = p[2] ^ c2;
    assign Sum[3] = p[3] ^ c3;
    assign Cout = c4;

    // Señales de grupo de P y G
    assign P_s = p[3] & p[2] & p[1] & p[0];
    assign G_s = g[3] |(p[3] & g[2]) |(p[3] & p[2] & g[1]) |(p[3] & p[2] & p[1] & g[0]);                            
endmodule

module CLA_16bits (
    input  wire [15:0] A,    // Primer operando      
    input  wire [15:0] B,    // Segundo operando     
    input  wire        Cin,  // Acarreo inicial      
    output wire [15:0] Sum,  // Suma 
    output wire        Cout  // Acarreo final        
);
    // Señales por bloque de 4 bits
    wire [3:0] P, G;    // P_group y G_group de cada bloque
    wire C4, C8, C12, C16;

    // Carry de bloque
    assign C4  = G[0] | (P[0] & Cin);
    assign C8  = G[1] | (P[1] & C4);
    assign C12 = G[2] | (P[2] & C8);
    assign C16 = G[3] | (P[3] & C12);
    assign Cout = C16;

    // Instancias de los cuatro bloques CLA de 4 bits
    CLABloque U0 (
        .A(A[3:0]),
        .B(B[3:0]),
        .Cin(Cin),
        .Sum(Sum[3:0]), 
        .Cout(), //  <--- Cout desconectado dado que se hace el lookahead para adelantar el acarreo.
        .P_s(P[0]), 
        .G_s(G[0])
    );

    CLABloque U1 (
        .A(A[7:4]),   
        .B(B[7:4]),   
        .Cin(C4),
        .Sum(Sum[7:4]), 
        .Cout(), 
        .P_s(P[1]), 
        .G_s(G[1])
    );

    CLABloque U2 (
        .A(A[11:8]),  
        .B(B[11:8]),  
        .Cin(C8),
        .Sum(Sum[11:8]), 
        .Cout(), 
        .P_s(P[2]), 
        .G_s(G[2])
    );

    CLABloque U3 (
        .A(A[15:12]), 
        .B(B[15:12]), 
        .Cin(C12),
        .Sum(Sum[15:12]), 
        .Cout(), 
        .P_s(P[3]), 
        .G_s(G[3])
    );
endmodule
