// seven_seg_driver.sv
// Muestra hasta 4 dígitos hexadecimales en el display de 7 segmentos
// Multiplexa los dígitos y convierte cada nibble (4 bits) en segmentos

module seven_seg_driver (

  input  logic        clk,        // reloj del sistema
  input  logic [15:0] val,        // valor a mostrar (hasta 16 bits)
  output logic [6:0]  seg,        // segmentos del display (a–g)
  output logic [7:0]  an          // ánodos (selección de dígito)

);

  // ____________________________________________________________________
  // 1. División del valor en 4 nibbles (4 bits por dígito)
  // ____________________________________________________________________
  logic [3:0] digit [3:0];

  assign digit[0] = val[3:0];     // dígito menos significativo
  assign digit[1] = val[7:4];
  assign digit[2] = val[11:8];
  assign digit[3] = val[15:12];

  // ____________________________________________________________________
  // 2. Contador para multiplexar los dígitos
  // ____________________________________________________________________
  logic [15:0] refresh_counter;
  logic [1:0]  digit_select;      // selecciona uno de los 4 dígitos

  always_ff @(posedge clk) begin
    refresh_counter <= refresh_counter + 1;
    digit_select    <= refresh_counter[15:14]; // cambia cada ~1 ms
  end

  // ____________________________________________________________________
  // 3. Conversión de nibble a segmentos
  // ____________________________________________________________________
  logic [6:0] seg_data;

  always_comb begin
    case (digit[digit_select])
      4'h0: seg_data = 7'b1000000;
      4'h1: seg_data = 7'b1111001;
      4'h2: seg_data = 7'b0100100;
      4'h3: seg_data = 7'b0110000;
      4'h4: seg_data = 7'b0011001;
      4'h5: seg_data = 7'b0010010;
      4'h6: seg_data = 7'b0000010;
      4'h7: seg_data = 7'b1111000;
      4'h8: seg_data = 7'b0000000;
      4'h9: seg_data = 7'b0010000;
      4'hA: seg_data = 7'b0001000;
      4'hB: seg_data = 7'b0000011;
      4'hC: seg_data = 7'b1000110;
      4'hD: seg_data = 7'b0100001;
      4'hE: seg_data = 7'b0000110;
      4'hF: seg_data = 7'b0001110;
      default: seg_data = 7'b1111111;
    endcase
  end

  // ____________________________________________________________________
  // 4. Asignación de salida
  // ____________________________________________________________________
  assign seg = seg_data;

  // Activar solo el dígito correspondiente (anodos activos en bajo)
  always_comb begin
    an = 8'b11111111;
    case (digit_select)
      2'd0: an[0] = 0;
      2'd1: an[1] = 0;
      2'd2: an[2] = 0;
      2'd3: an[3] = 0;
      default: an = 8'b11111111;
    endcase
  end

endmodule
