`timescale 1ns/1ps 

module Display#( 
    parameter bit Simulacion = 0, 
    parameter int CLK_HZ = 16_000_000) 
(   
//=== Elementos de la FPGA ===  
    input logic          clk, reset,
    output logic [6:0]   SEG,              //los 7 segmentos físicos del display
    output logic [7:0]   AN,              // dígitos activos en bajo
    
    input logic          SEG_we,
    input logic  [31:0]  SEG_wdata,

//=== Display ===
    output logic [31:0]  DisplayValor, 
    output logic         PulsoMitad, 
    output logic         PulsoFin 
    ); 

                                                                           
// ------------------------------------------------------------------- 
//Contador de Display que se encarga de que cada valor se vea por 2 segundos 
// ------------------------------------------------------------------- 
    
localparam int MAX_COUNT = Simulacion ? 20 : (CLK_HZ * 2); // usa CLK_HZ param 
localparam int unsigned HALF = MAX_COUNT/2; 
logic VentanaActiva; 
logic[$clog2(MAX_COUNT)-1:0] DisplayContador; 
    
        always_ff @(posedge clk or posedge reset) begin 
            if (reset) begin 
                VentanaActiva <= 1'b0;
                DisplayContador <= '0; 
                PulsoMitad <= 1'b0; 
                PulsoFin <= 1'b0; 
            end else begin 
                PulsoMitad <= 1'b0; 
                PulsoFin<= 1'b0; 
                if(SEG_we) begin //iniciar el display
                    VentanaActiva <= 1'b1; //Iniciar el contador
                    DisplayContador <= MAX_COUNT -1; 
                end else 
                if (VentanaActiva) begin 
                    if(DisplayContador == 0) begin 
                        PulsoFin <= 1'b1;
                        VentanaActiva <= 1'b0; 
                    end else begin 
                        if (DisplayContador == HALF)
                            PulsoMitad <= 1'b1; 
                            DisplayContador <= DisplayContador - 1'b1; 
                    end 
                end 
            end 
        end 
              
// ------------------------------------------------------------------- 
//Iniciar el Display para que muestre los valores correspondientes 
// -------------------------------------------------------------------
logic disp_arm;
 logic [7:0] DisplayValor_reg; 
 assign DisplayValor = DisplayValor_reg;
 
always_ff @(posedge clk or posedge reset) begin
  if (reset) begin
    DisplayValor_reg <= 8'h00;
    disp_arm         <= 1'b0;
  end else begin
    if (SEG_we) begin
      DisplayValor_reg <= SEG_wdata;
      disp_arm <= 1'b1;
    end else if (disp_arm) begin
      disp_arm <= 1'b0;
    end
  end
end

    typedef enum logic [1:0] {F_OFF, F_D1, F_D2} fase_t;
    fase_t fase;
    
    logic [7:0] val_reg;
    wire [3:0] dig0 = val_reg[3:0];
    wire [3:0] dig1 = val_reg[7:4]; 

    always_ff @(posedge clk or posedge reset) begin
        if (reset) val_reg <= 8'h00;
        else if (SEG_we) val_reg <= DisplayValor_reg; // latch al comenzar
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) fase <= F_OFF;
        else if (SEG_we)            fase <= F_D1;     // comienza
        else if (PulsoMitad  && fase==F_D1) fase <= F_D2;    // mitad
        else if (PulsoFin)                  fase <= F_OFF;   // final
    end

    always_comb begin
        AN  = 8'b1111_1111;  // off
        SEG = 7'b111_1111;
        unique case (fase)
            F_D1: begin AN=8'b1111_1110; SEG=hex(dig1); end   // 1er dígito
            F_D2: begin AN=8'b1111_1101; SEG=hex(dig0); end // 2º dígito
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