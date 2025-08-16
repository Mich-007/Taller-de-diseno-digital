`timescale 1ns / 1ps
module TestbenchDecodificador;
    logic [3:0] user_input;
    logic [6:0] display_out;
    logic [3:0] SW0, SW1, SW2, SW3, seg_debug,an_debug;      // switches
    logic [1:0]btn;        // botón 1
    
    multiplexor uut(
        .user_input(user_input), // conectamos señales TB ? módulo
        .display_out(display_out));
        
    decodificador uut_dec (
        .SW0(SW0),
        .SW1(SW1),
        .SW2(SW2),
        .SW3(SW3),
        .BTN(btn),
        .an_debug(an_debug),
        .seg_debug(seg_debug));

        
    initial begin
        // Estímulos de prueba
        user_input = '0;
        btn = 2'b00;#1;
        SW0 = 4'b0000; SW1 = 4'b0000; SW2 = 4'b0000; SW3 = 4'b0000;#30
        user_input = 4'b0001; #30;
        user_input = 4'b0010; #30;
        user_input = 4'b1111; #30;
        btn = 2'b00;#1;
        SW0 = 4'b0011; #30;
        SW0 = 4'b0001; #30;
        SW1 = 4'b0100; #30;
        
        //reset
        SW0 = 4'b0000; SW1 = 4'b0000; SW2 = 4'b0000; SW3 = 4'b0000;#30
        btn = 2'b01;#1;
        //caso correcto
        SW1 = 4'b0110; #30;
        //casos incorrectos
        SW1 = 4'b0100; #30;
        SW0 = 4'b0001; #30;

        
        //reset
        SW0 = 4'b0000; SW1 = 4'b0000; SW2 = 4'b0000; SW3 = 4'b0000;#30
        btn = 2'b10;#1;
        //caso correcto
        SW2 = 4'b1000; #30;

        //casos incorrectos
        SW2 = 4'b1001; #30;
        SW0 = 4'b0001; #30;
        
        //reset
        SW0 = 4'b0000; SW1 = 4'b0000; SW2 = 4'b0000; SW3 = 4'b0000;#30
        btn = 2'b11;#1;
        //caso correcto
        SW3 = 4'b1001; #30;
        //casos incorrectos
        SW3 = 4'b1101; #30;
        SW0 = 4'b0001; #30;

    end
    
endmodule
