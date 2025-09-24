// hex7seg.sv
`timescale 1ns/1ps
// Salidas activas en bajo para Nexys-4 (común ánodo)
module hex7seg(
    input  logic [3:0] x,
    output logic [6:0] a_to_g   // {g,f,e,d,c,b,a}
);
    always_comb begin
        unique case (x)
            4'h0: a_to_g = 7'b1000000;
            4'h1: a_to_g = 7'b1111001;
            4'h2: a_to_g = 7'b0100100;
            4'h3: a_to_g = 7'b0110000;
            4'h4: a_to_g = 7'b0011001;
            4'h5: a_to_g = 7'b0010010;
            4'h6: a_to_g = 7'b0000010;
            4'h7: a_to_g = 7'b1111000;
            4'h8: a_to_g = 7'b0000000;
            4'h9: a_to_g = 7'b0010000;
            4'hA: a_to_g = 7'b0001000;
            4'hB: a_to_g = 7'b0000011;
            4'hC: a_to_g = 7'b1000110;
            4'hD: a_to_g = 7'b0100001;
            4'hE: a_to_g = 7'b0000110;
            4'hF: a_to_g = 7'b0001110;
            default: a_to_g = 7'b1111111;
        endcase
    end
endmodule
