// ___________________________________________________________________________
// seven_seg_driver.sv
// Driver parametrizable para display de 7 segmentos (DIGITS nibbles)
// - Salidas registradas y reset síncrono
// ___________________________________________________________________________

module seven_seg_driver #(
  parameter int DIGITS = 4,
  parameter int REFRESH_CNT_WIDTH = 16
)(
  input  logic                 clk,
  input  logic                 rst,            // reset síncrono activo alto
  input  logic [DIGITS*4-1:0]  val,            // valor a mostrar (4 bits por dígito)
  output logic [6:0]           seg,            // segmentos
  output logic [7:0]           an              // ánodos (hasta 8)
);

  // split nibbles
  logic [3:0] digit [DIGITS-1:0];
  genvar i;
  generate
    for (i = 0; i < DIGITS; i = i + 1) begin
      assign digit[i] = val[4*i +: 4];
    end
  endgenerate

  logic [REFRESH_CNT_WIDTH-1:0] refresh_counter;
  logic [$clog2(DIGITS)-1:0] digit_select;

  always_ff @(posedge clk) begin
    if (rst) refresh_counter <= '0;
    else     refresh_counter <= refresh_counter + 1'b1;
  end

  assign digit_select = refresh_counter[REFRESH_CNT_WIDTH-1 -: $clog2(DIGITS)];

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

  // registrar salidas para evitar glitches
  logic [6:0] seg_reg;
  logic [7:0] an_reg;

  always_ff @(posedge clk) begin
    if (rst) begin
      seg_reg <= 7'b1111111;
      an_reg  <= 8'hFF;
    end else begin
      seg_reg <= seg_data;
      an_reg  <= 8'hFF;
      if (digit_select < DIGITS) an_reg[digit_select] <= 1'b0; // activo bajo
    end
  end

  assign seg = seg_reg;
  assign an  = an_reg;

endmodule
