`timescale 1ns / 1ps
module TestbenchDecodificador;
    logic [6:0]  SEG;      //displays de 7 segmentos
    logic [3:0]  AN, SW0, SW1, SW2, SW3;       //ánodos del display de siete segmentos y grupo de switches
    logic [1:0] BTN;       //botones 
       
    decodificador uut (
        .SW0(SW0),
        .SW1(SW1),
        .SW2(SW2),
        .SW3(SW3),
        .BTN(BTN),
        .AN(AN),
        .SEG(SEG)      
        );
       
    initial begin
    //caso #1. Primer grupo de switches
    BTN = 2'b00;#1;
    //caso correcto
    SW0 = 4'b0011; #30;
    //casos incorrectos
    SW0 = 4'b0001; #30;
    SW1 = 4'b0100; #30;
    
    //caso #2. Segundo grupo de switches    
    BTN = 2'b01;#1;
    //caso correcto
    SW1 = 4'b0110; #30;
    //casos incorrectos
    SW1 = 4'b0100; #30;
    SW0 = 4'b0001; #30;
    
    //caso #3. Tercer grupo de switches  
    BTN = 2'b10;#1;
    //caso correcto
    SW2 = 4'b1000; #30;
    //casos incorrectos
    SW2 = 4'b1001; #30;
    SW0 = 4'b0001; #30;
    
    //caso #4. Cuarto grupo de switches      
    BTN = 2'b11;#1;
    //caso correcto
    SW3 = 4'b1001; #30;
    //casos incorrectos
    SW3 = 4'b1101; #30;
    SW0 = 4'b0001; #30;

    end
    
endmodule
