`timescale 1ns / 1ps

module mux2_1 #(parameter N = 32)(     // N = bits de ancho
	input  logic [N-1:0] d0, d1,     // entradas
	input  logic         sel,          // seleccionador 
	output logic [N-1:0] y           // salida
);
	always_comb begin
    	case (sel)
            1'b0 : y = d0;
            1'b1 : y = d1;
            default: y = '0;
    	endcase
	end
endmodule
