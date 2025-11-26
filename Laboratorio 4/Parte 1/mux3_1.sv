`timescale 1ns / 1ps
module mux3_1 #(parameter N = 32)(   // N = bits de ancho
	input  logic [N-1:0] d0, d1, d2, // entradas
	input  logic [1:0]   sel,        // seleccionador 
	output logic [N-1:0] y           // salida
);
	always_comb begin
    	case (sel)
            2'b00 : y = d0;
            2'b01 : y = d1;
            2'b10 : y = d2;
            default: y = '0;
    	endcase
	end
endmodule
