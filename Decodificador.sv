`timescale 1ns / 1ps
module decodificador(
    input  logic [3:0]  SW0,      // switch[3:0]
    input  logic [3:0]  SW1,      // switch[7:4]
    input  logic [3:0]  SW2,      // switch[11:8]
    input  logic [3:0]  SW3,      // switch[15:12]
    input  logic [1:0]  BTN,      // los dos botnoes para seleccionar el grupo de switches
    output logic [6:0]  SEG,      // displays de 7 segmentos
    output logic [7:0]  AN,       // ánodos del display
    output logic [3:0]  seg_debug, //valor para observar el display de 7 segmentos como decimal en el testbench
    output logic [3:0]  an_debug    //valor para observar el ánodo del display de 7 segmentos como decimal en el testbench
);

  always_comb begin
    // Apagado por defecto
    SEG         = 7'b111_1111;
    AN          = 8'b1111_1111;
    seg_debug = 4'hF; // F = OFF
    an_debug = 4'hF;

    if      (BTN == 2'b00 && SW0 == 4'b0011) begin
      AN          = 8'b0111_1111;  // enciende dígito 0 (ajusta si tu mapeo es distinto)
      SEG         = 7'b000_0110;   // 3 (activos en bajo)
      seg_debug = 4'd3;
      an_debug = 4'd2;
      $display("[%0t] 3", $time);
    end
    else if (BTN == 2'b01 && SW1 == 4'b0110) begin
      AN          = 8'b1011_1111;  // dígito 1
      SEG         = 7'b010_0000;   // 6
      seg_debug = 4'd6;
      an_debug = 4'd2;
      $display("[%0t] 6", $time);
    end
    else if (BTN == 2'b10 && SW2 == 4'b1000) begin
      AN          = 8'b1101_1111;  // dígito 2
      SEG         = 7'b000_0000;   // 8
      seg_debug = 4'd8;
      an_debug = 4'd3;
      $display("[%0t] 8", $time);
    end
    else if (BTN == 2'b11 && SW3 == 4'b1001) begin
      AN          = 8'b1110_1111;  // dígito 3
      SEG         = 7'b000_1100;   // 9
      seg_debug = 4'd9;
      an_debug = 4'd4;
      $display("[%0t] 9", $time);
    end
    // else: queda apagado con digit_debug = F
  end

endmodule
