`timescale 1ns / 1ps

module Display_7seg_32bits(
    input  logic clk,               // reloj de 100 MHz
    input  logic [31:0] data,       // datos de 32 bits (8 d�gitos hexadecimales)
    input  logic enable,            // 1 = encendido, 0 = apagado
    output logic [7:0] an,          // 8 �nodos activos bajos
    output logic [7:0] seg          // segmentos (a-g + punto)
);

    // ------------------------------------------------------------
    // Se�ales internas
    // ------------------------------------------------------------
    logic [2:0] sel;                // selector del d�gito actual (0-7)
    logic [3:0] nibble;             // nibble actual para convertir
    logic [19:0] refresh_counter;   // controla velocidad del multiplexado

    // ------------------------------------------------------------
    // Tabla de segmentos (para c�todo com�n, invertir si usas �nodo com�n)
    // ------------------------------------------------------------
    function [6:0] seg_map(input [3:0] val);
        case (val)
            4'h0: seg_map = 7'b1000000;
            4'h1: seg_map = 7'b1111001;
            4'h2: seg_map = 7'b0100100;
            4'h3: seg_map = 7'b0110000;
            4'h4: seg_map = 7'b0011001;
            4'h5: seg_map = 7'b0010010;
            4'h6: seg_map = 7'b0000010;
            4'h7: seg_map = 7'b1111000;
            4'h8: seg_map = 7'b0000000;
            4'h9: seg_map = 7'b0010000;
            4'hA: seg_map = 7'b0001000;
            4'hB: seg_map = 7'b0000011;
            4'hC: seg_map = 7'b1000110;
            4'hD: seg_map = 7'b0100001;
            4'hE: seg_map = 7'b0000110;
            4'hF: seg_map = 7'b0001110;
            default: seg_map = 7'b1111111;
        endcase
    endfunction

    // ------------------------------------------------------------
    // Contador para multiplexado (ajustado para 100 MHz)
    // ------------------------------------------------------------
    always_ff @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
        sel <= refresh_counter[19:17];   // cambia de d�gito cada ~1.3 ms aprox.
    end

    // ------------------------------------------------------------
    // Selecci�n del nibble correspondiente al d�gito activo
    // ------------------------------------------------------------
    always_comb begin
        case (sel)
            3'd0: nibble = data[3:0];
            3'd1: nibble = data[7:4];
            3'd2: nibble = data[11:8];
            3'd3: nibble = data[15:12];
            3'd4: nibble = data[19:16];
            3'd5: nibble = data[23:20];
            3'd6: nibble = data[27:24];
            3'd7: nibble = data[31:28];
            default: nibble = 4'h0;
        endcase
    end

    // ------------------------------------------------------------
    // Control de �nodos (activos bajos)
    // ------------------------------------------------------------
    always_comb begin
        if (enable) begin
            an = 8'b11111111;
            an[sel] = 1'b0; // activa solo el d�gito actual
        end else begin
            an = 8'b11111111; // apaga todos los d�gitos
        end
    end

    // ------------------------------------------------------------
    // Control de segmentos
    // ------------------------------------------------------------
    always_comb begin
        if (enable)
            seg = {1'b1, seg_map(nibble)};  // DP apagado (1)
        else
            seg = 8'b11111111;              // todo apagado
    end
endmodule