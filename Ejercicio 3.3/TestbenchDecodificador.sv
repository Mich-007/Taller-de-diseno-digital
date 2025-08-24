`timescale 1ns / 1ps
module TestbenchDecodificador;
    logic [6:0]  SEG;      //display de 7 segmentos
    logic [7:0]  AN;       //ánodos del display de 7 segmentos
    logic [3:0] SW0, SW1, SW2, SW3;       //grupos de switches
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
    BTN = 2'b00;#10;
    SW0 = 4'hA; #30;
    SW0 = 4'h8; #30;
    
    //caso #2. Segundo grupo de switches  
    BTN = 2'b01;#10;  
    SW1 = 4'h5; #30;
    SW1 = 4'h1; #30; 
    
    //caso #3. Tercer grupo de switches  
    BTN = 2'b10;#10;
    SW2 = 4'h3; #30;
    SW2 = 4'h9; #30;   
    
    //caso #4. Cuarto grupo de switches  
    BTN = 2'b11;#10;    
    SW3 = 4'h0; #30;
    SW3 = 4'hB; #30;
    
    end
    
endmodule

