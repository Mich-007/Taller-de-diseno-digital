`timescale 1ns/1ps
module Display( 
    input logic        clk, reset,
    input logic        Displayiniciar, PulsoMitad, PulsoFin,
    input logic [15:0] DisplayValor,        // dos nibbles hex
    output logic [6:0] SEG,                  // a..g activos en bajo
    output logic [7:0] AN,              // dígitos activos en bajo
    output logic [1:0] DisplayActivado
);

    typedef enum logic [1:0] {F_OFF, F_D1, F_D2} fase_t;
    fase_t fase;
    
    logic [7:0] val_reg;
    wire [3:0] dig0 = val_reg[3:0];
    wire [3:0] dig1 = val_reg[7:4]; 

    always_ff @(posedge clk or posedge reset) begin
        if (reset) val_reg <= 8'h00;
        else if (Displayiniciar) val_reg <= DisplayValor; // latch al comenzar
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) fase <= F_OFF;
        else if (Displayiniciar)            fase <= F_D1;     // comienza
        else if (PulsoMitad  && fase==F_D1) fase <= F_D2;    // mitad
        else if (PulsoFin)                  fase <= F_OFF;   // final
    end

    always_comb begin
        AN  = 8'b1111_1111;  // off
        SEG = 7'b111_1111;
        unique case (fase)
            F_D1: begin AN=8'b1111_1110; SEG=hex(dig0); end   // 1er dígito
            F_D2: begin AN=8'b1111_1101; SEG=(dig1==0)?7'b111_1111:hex(dig1); end // 2º dígito
            default: ;
        endcase
    end

// -------------------------------------------------------------------
//Decodificador de siete segmentos
// -------------------------------------------------------------------  
    function automatic logic [6:0] hex (input logic [3:0] nibble);
        case (nibble)
            4'h0: hex = 7'b1000000;
            4'h1: hex = 7'b1111001;
            4'h2: hex = 7'b0100100;
            4'h3: hex = 7'b0110000;
            4'h4: hex = 7'b0011001;
            4'h5: hex = 7'b0010010;
            4'h6: hex = 7'b0000010;
            4'h7: hex = 7'b1111000;
            4'h8: hex = 7'b0000000;
            4'h9: hex = 7'b0010000;
            4'hA: hex = 7'b0001000;
            4'hB: hex = 7'b0000011;
            4'hC: hex = 7'b1000110;
            4'hD: hex = 7'b0100001;
            4'hE: hex = 7'b0000110;
            4'hF: hex = 7'b0001110;
            default: hex = 7'b1111111; // OFF
        endcase
    endfunction

endmodule 
