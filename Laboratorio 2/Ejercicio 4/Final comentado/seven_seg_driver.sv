// ___________________________________________________________________________
// seven_seg_driver.sv
// Driver parametrizable para display de 7 segmentos (DIGITS nibbles)
// - Salidas registradas y reset síncrono
// ___________________________________________________________________________

module seven_seg_driver #(                          // inicio del módulo parametrizable
  parameter int DIGITS = 4,                         // número de dígitos multiplexados (nibbles)
  parameter int REFRESH_CNT_WIDTH = 16              // ancho del contador de refresco
)(
  input  logic                 clk,                 // reloj del sistema para multiplexado
  input  logic                 rst,                 // reset síncrono activo alto
  input  logic [DIGITS*4-1:0]  val,                 // valor a mostrar: 4 bits por dígito (LSB primer dígito)
  output logic [6:0]           seg,                 // líneas de segmentos (a..g)
  output logic [7:0]           an                   // líneas de ánodos (una por dígito, activo bajo)
);

  // split nibbles
  logic [3:0] digit [DIGITS-1:0];                   // array de nibbles, cada uno corresponde a un dígito
  genvar i;
  generate
    for (i = 0; i < DIGITS; i = i + 1) begin         // generar asignaciones para extraer cada nibble
      assign digit[i] = val[4*i +: 4];               // slice de 4 bits: val[4*i +: 4] → digit[i]
    end
  endgenerate

  logic [REFRESH_CNT_WIDTH-1:0] refresh_counter;    // contador que determina la velocidad de multiplexado
  logic [$clog2(DIGITS)-1:0] digit_select;          // índice actual del dígito activo (ancho mínimo necesario)

  // contador síncrono de refresco
  always_ff @(posedge clk) begin
    if (rst) refresh_counter <= '0;                 // al reset poner contador a 0
    else     refresh_counter <= refresh_counter + 1'b1; // incrementar en cada flanco de clock
  end

  // seleccionar bits superiores del contador para formar el índice del dígito
  assign digit_select = refresh_counter[REFRESH_CNT_WIDTH-1 -: $clog2(DIGITS)];
                                                  // toma $clog2(DIGITS) bits comenzando en el MSB del campo relevante
                                                  // así el periodo visible de cada dígito depende de REFRESH_CNT_WIDTH

  logic [6:0] seg_data;                             // patrón combinacional para segmentos según el nibble

  // tabla combinacional que mapea valor hex a patrón de segmentos (suponiendo segmentos activos bajos=0)
  always_comb begin
    case (digit[digit_select])
      4'h0: seg_data = 7'b1000000;                  // patrón para '0' (segmento a..g)
      4'h1: seg_data = 7'b1111001;                  // patrón para '1'
      4'h2: seg_data = 7'b0100100;                  // patrón para '2'
      4'h3: seg_data = 7'b0110000;                  // patrón para '3'
      4'h4: seg_data = 7'b0011001;                  // patrón para '4'
      4'h5: seg_data = 7'b0010010;                  // patrón para '5'
      4'h6: seg_data = 7'b0000010;                  // patrón para '6'
      4'h7: seg_data = 7'b1111000;                  // patrón para '7'
      4'h8: seg_data = 7'b0000000;                  // patrón para '8'
      4'h9: seg_data = 7'b0010000;                  // patrón para '9'
      4'hA: seg_data = 7'b0001000;                  // patrón para 'A'
      4'hB: seg_data = 7'b0000011;                  // patrón para 'b' (minúscula)
      4'hC: seg_data = 7'b1000110;                  // patrón para 'C'
      4'hD: seg_data = 7'b0100001;                  // patrón para 'd' (minúscula)
      4'hE: seg_data = 7'b0000110;                  // patrón para 'E'
      4'hF: seg_data = 7'b0001110;                  // patrón para 'F'
      default: seg_data = 7'b1111111;               // todos apagados (valor por defecto, segmentos inactivos)
    endcase
  end

  // registrar salidas para evitar glitches en el multiplexado
  logic [6:0] seg_reg;                              // registro para segmentos
  logic [7:0] an_reg;                               // registro para ánodos

  always_ff @(posedge clk) begin
    if (rst) begin
      seg_reg <= 7'b1111111;                        // en reset, apagar segmentos (asumiendo activo bajo)
      an_reg  <= 8'hFF;                             // en reset, desactivar todos los ánodos (activo bajo = 1=inactivo)
    end else begin
      seg_reg <= seg_data;                          // actualizar patrón de segmentos con el valor combinacional
      an_reg  <= 8'hFF;                             // por defecto todos inactivos
      if (digit_select < DIGITS)                    // si el índice es válido dentro de DIGITS
        an_reg[digit_select] <= 1'b0;               // activar (activo bajo) el ánodo correspondiente
    end
  end

  assign seg = seg_reg;                             // salida física de segmentos (registrada)
  assign an  = an_reg;                              // salida física de ánodos (registrada)

endmodule                                            // fin del módulo
