always_comb begin
    AN = 8'hFF;
    SW = 4'h0; //estados iniciales, donde todo esté apagado
    unique case (BTN)
    2'b00: begin //si los dos botones tienen un valor de 00 se activa el primer ánodo y se enciende el display
     AN[0] = 1'b0;    //de acuerdo al número al que corresponda la secuencia de los switches
     SW = SW0;
     if (SW == SW1 || SW == SW2 || SW == SW3) begin
        $error("Error: este no es el grupo seleccionado SW=%0d", SW);
        end
    end 
    2'b01: begin //si los dos botones tienen un valor de 01 se activa el segundo ánodo y se enciende el display
     AN[1] = 1'b0;
     SW = SW1;
     if (SW == SW0 || SW == SW2 || SW == SW3) begin
        $error("Error: este no es el grupo seleccionado SW=%0d", SW);
        end
    end 
    2'b10: begin  //si los dos botones tienen un valor de 10 se activa el tercer ánodo y se enciende el display
     AN[2] = 1'b0;
     SW = SW2;
     if (SW == SW0 || SW == SW1 || SW == SW2) begin
        $error("Error: este no es el grupo seleccionado SW=%0d", SW);
        end
    end 
    2'b11: begin //si los dos botones tienen un valor de 11 se activa el cuarto ánodo y se enciende el display
     AN[3] = 1'b0;
     SW = SW3;
     if (SW == SW0 || SW == SW1 || SW == SW2) begin
        $error("Error: este no es el grupo seleccionado SW=%0d", SW);
        end
    end
    endcase
// Decodificador HEX a 7 segmentos (activo en bajo): {g,f,e,d,c,b,a}
    unique case (SW)
        4'h0: SEG = 7'b1000000;
        4'h1: SEG = 7'b1111001;
        4'h2: SEG = 7'b0100100;
        4'h3: SEG = 7'b0110000;
        4'h4: SEG = 7'b0011001;
        4'h5: SEG = 7'b0010010;
        4'h6: SEG = 7'b0000010;
        4'h7: SEG = 7'b1111000;
        4'h8: SEG = 7'b0000000;
        4'h9: SEG = 7'b0010000;
        4'hA: SEG = 7'b0001000;
        4'hB: SEG = 7'b0000011;
        4'hC: SEG = 7'b1000110;
        4'hD: SEG = 7'b0100001;
        4'hE: SEG = 7'b0000110;
        4'hF: SEG = 7'b0001110;
        default: SEG = 7'b1111111; // OFF
      endcase
    end

endmodule

