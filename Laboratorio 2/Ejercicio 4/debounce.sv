// debounce.sv
// Módulo para eliminar rebotes mecánicos en botones físicos
// - Sincroniza la señal del botón con el reloj del sistema
// - Filtra fluctuaciones rápidas (rebotes) que ocurren al presionar o soltar
// - Genera una salida limpia y estable (db_out) que dura al menos un ciclo

module debounce (
  input  logic clk,        // Reloj del sistema (ej. 100 MHz)
  input  logic btn,        // Señal directa del botón (ruidosa)
  output logic db_out      // Señal debounced (limpia y estable)
);

  // _______________________________________________________________________________
  // 1. Sincronización doble para evitar metastabilidad
  // _______________________________________________________________________________
  // Los botones son señales asíncronas respecto al reloj del sistema.
  // Para evitar errores de sincronización, se usan dos flip-flops en cascada.
  logic btn_sync_0, btn_sync_1;

  // _______________________________________________________________________________
  // 2. Contador para medir estabilidad de la señal
  // _______________________________________________________________________________
  // Si la señal permanece estable durante suficiente tiempo (ej. 65536 ciclos),
  // se considera válida y se actualiza la salida.
  logic [15:0] counter;    // Contador de estabilidad
  logic stable;            // Valor estable detectado

  // _______________________________________________________________________________
  // 3. Sincronización de la señal del botón
  // _______________________________________________________________________________
  // Captura la señal del botón en dos etapas para alinearla con el reloj
  always_ff @(posedge clk) begin
    btn_sync_0 <= btn;         // Primer flip-flop: captura la señal
    btn_sync_1 <= btn_sync_0;  // Segundo flip-flop: estabiliza la señal
  end

  // _______________________________________________________________________________
  // 4. Lógica de debounce
  // _______________________________________________________________________________
  // Si la señal sincronizada cambia respecto al valor estable anterior,
  // se empieza a contar. Si se mantiene igual por suficiente tiempo,
  // se acepta como nueva señal estable.
  always_ff @(posedge clk) begin
    if (btn_sync_1 != stable) begin
      counter <= counter + 1;  // Incrementa contador si hay cambio
      if (counter == 16'hFFFF) begin
        stable  <= btn_sync_1; // Actualiza valor estable
        counter <= 0;          // Reinicia contador
      end
    end else begin
      counter <= 0;            // Si no hay cambio, reinicia contador
    end
  end

  // _______________________________________________________________________________
  // 5. Asignación de salida debounced
  // _______________________________________________________________________________
  // La salida debounced refleja el valor estable detectado
  assign db_out = stable;

endmodule
