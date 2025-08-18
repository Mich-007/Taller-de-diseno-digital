`timescale 1ns / 1ps
module decodificador(
    input  logic [3:0]  SW0,      // switches 
    input  logic [3:0]  SW1,      // switches 
    input  logic [3:0]  SW2,      // switches 
    input  logic [3:0]  SW3,      // switches 
    input  logic [1:0]  BTN,      // los dos botones para seleccionar el grupo de switches
    output logic [6:0]  SEG,      // displays de 7 segmentos
    output logic [3:0]  AN,       // ánodos del display de 7 segmentos
    output logic [1:0] LED
);


  always_comb begin
    // Apagado por defecto
    SEG = 7'b111_1111;
    AN = 4'b1111;
    LED = 2'b11;
    if (BTN == 2'b00) //se revisa que lo botones estén en el modo esperado para el primer  grupo de switches
        LED = 2'b00;  //se usa sólo para el funcionamiento físico, donde los leds se encienden para visualizar el modo en el que está la FPGA, dependen de los botones
        if (SW0 == 4'b0011) begin //se revisa que los switches estén en el estado 
        AN          = 4'b0111;  // enciende dígito 0 (ajusta si tu mapeo es distinto)
        SEG         = 7'b000_0110;   // 3 (activos en bajo)
        end
    else if (BTN == 2'b01)
        LED = 2'b01;
        if(SW1 == 4'b0110) begin
            AN          = 4'b1011;  // dígito 1
            SEG         = 7'b010_0000;   // 6
        end
    else if (BTN == 2'b10)
        LED = 2'b10;
        if (SW2 == 4'b1000) begin
            AN          = 4'b1101;  // dígito 2
            SEG         = 7'b000_0000;   // 8
        end

    else if (BTN == 2'b11)
        LED = 2'b11;
        if (SW3 == 4'b1001) begin
            AN          = 4'b1110;  // dígito 3
            SEG         = 7'b000_1100;   // 9
        end
    // else: queda apagado con digit_debug = F
    end
endmodule
