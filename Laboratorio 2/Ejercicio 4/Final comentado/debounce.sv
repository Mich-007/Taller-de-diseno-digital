// ============================================================
// debounce.sv
// Debounce parametrizable con reset síncrono y salida registrada
// ============================================================

module debounce #(
  parameter int CNT_WIDTH = 18,             // ancho del contador de estabilidad (bits)
  parameter int THRESH = 200000             // umbral en ciclos de reloj para considerar el botón estable
)(
  input  logic clk,                         // reloj del sistema (flanco posedge usado)
  input  logic rst,                         // reset síncrono activo alto (inicializa todo)
  input  logic btn,                         // señal directa del botón (puede rebotar)
  output logic db_out                       // salida debounced (registrada)
);

  // doble sincronizador para mitigar metastabilidad al traer la señal asíncrona al dominio de clk
  logic btn_sync_0, btn_sync_1;

  // contador que mide cuánto tiempo la señal sincronizada se mantiene constante
  logic [CNT_WIDTH-1:0] counter;

  // señal que representa el estado estable detectado tras superar el umbral
  logic stable;

  // ------------------------------------------------------------------
  // Doble sincronizador
  // - Primera etapa captura la señal asíncrona en clk
  // - Segunda etapa reduce riesgo de metastabilidad al propagar a lógica síncrona
  // - En reset se inicializan ambos flops a 0 para un estado determinista
  // ------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (rst) begin
      btn_sync_0 <= 1'b0;                    // inicializa flop de sincronización 0
      btn_sync_1 <= 1'b0;                    // inicializa flop de sincronización 1
    end else begin
      btn_sync_0 <= btn;                     // captar señal asíncrona en primer flop
      btn_sync_1 <= btn_sync_0;              // propagar al segundo flop (ya sincronizada)
    end
  end

  // ------------------------------------------------------------------
  // Contador de estabilidad
  // - Si la señal sincronizada difiere de 'stable', incrementa el contador.
  // - Si el contador alcanza THRESH se acepta el nuevo valor como estable.
  // - Si la señal es igual a 'stable', resetear el contador a 0.
  // - Todo esto ocurre síncronamente con clk y con reset síncrono.
  // ------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= '0;                         // limpiar contador en reset
      stable  <= 1'b0;                       // estado estable por defecto = 0
    end else begin
      if (btn_sync_1 != stable) begin        // hay discrepancia entre sincronizada y estado estable
        counter <= counter + 1'b1;          // contar ciclos donde persiste el nuevo valor
        if (counter >= THRESH) begin        // si supera umbral => aceptar nuevo estado
          stable  <= btn_sync_1;            // actualizar estado estable
          counter <= '0;                    // reiniciar contador
        end
      end else begin
        counter <= '0;                      // si no hay cambio, mantener contador a cero
      end
    end
  end

  // ------------------------------------------------------------------
  // Salida registrada
  // - La salida db_out se actualiza síncronamente con clk a partir de 'stable'
  // - En reset, db_out se inicializa en 0 para comportamiento determinista
  // ------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (rst) db_out <= 1'b0;
    else     db_out <= stable;
  end

endmodule
