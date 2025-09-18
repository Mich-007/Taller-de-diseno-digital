// ============================================================
// debounce.sv
// Debounce parametrizable con reset síncrono y salida registrada
// ============================================================

module debounce #(
  parameter int CNT_WIDTH = 18,             // ancho del contador
  parameter int THRESH = 200000             // umbral (ciclos de reloj)
)(
  input  logic clk,
  input  logic rst,         // reset síncrono activo alto
  input  logic btn,         // señal directa del botón (asíncrona)
  output logic db_out       // señal debounced registrada
);

  logic btn_sync_0, btn_sync_1;
  logic [CNT_WIDTH-1:0] counter;
  logic stable;

  // doble sincronizador
  always_ff @(posedge clk) begin
    if (rst) begin
      btn_sync_0 <= 1'b0;
      btn_sync_1 <= 1'b0;
    end else begin
      btn_sync_0 <= btn;
      btn_sync_1 <= btn_sync_0;
    end
  end

  // contador de estabilidad
  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= '0;
      stable  <= 1'b0;
    end else begin
      if (btn_sync_1 != stable) begin
        counter <= counter + 1'b1;
        if (counter >= THRESH) begin
          stable  <= btn_sync_1;
          counter <= '0;
        end
      end else begin
        counter <= '0;
      end
    end
  end

  // salida registrada
  always_ff @(posedge clk) begin
    if (rst) db_out <= 1'b0;
    else     db_out <= stable;
  end

endmodule
