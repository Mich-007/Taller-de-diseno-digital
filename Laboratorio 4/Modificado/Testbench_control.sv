`timescale 1ns/1ps

// TESTBENCH para TOP con Sensor + Timer + Display (versión corregida y lista)
module tb_top;

  // ------------------------
  // Señales hacia el DUT
  // ------------------------
  logic        clk;
  logic        reset;
  logic [15:0] SW;

  wire [6:0]   SEG;
  wire [7:0]   AN;
  wire [15:0]  LED;
  wire [3:0]   st_dbg;

  // ------------------------
  // Instancia del DUT (Top)
  // ------------------------
  Top #(.Simulacion(1)) DUT (
      .clk_100 (clk),
      .reset   (reset),
      .SW      (SW),
      .SEG     (SEG),
      .AN      (AN),
      .LED     (LED),
      .st_dbg  (st_dbg)
  );

  // ------------------------
  // Clock (100 MHz en Sim)
  // ------------------------
  initial clk = 1'b0;
  always #5 clk = ~clk;   // 10 ns -> 100 MHz

  // ------------------------
  // Reloj interno (fallback)
  // ------------------------
  wire clk10;
  assign clk10 = (DUT.clk_10MHz === 1'bx) ? clk : DUT.clk_10MHz;

  task wait_clk(input int n);
    repeat(n) @(posedge clk10);
  endtask

  // ------------------------
  // Señales jerárquicas (seguras con condicionales)
  // ------------------------
  // Intentamos leer señales internas si existen; si no, usamos valores por defecto.
  function automatic logic exists_signal(input string path);
    // No hay forma portable de comprobar existencia en todos los simuladores desde SV,
    // así que esta función es solo indicativa; las asignaciones abajo usan $value$plusargs
    // o referencias jerárquicas directas con protección.
    exists_signal = 1'b1;
  endfunction

  // Rutas jerárquicas (pueden variar según tu Top)
  // Intentamos mapear PC e IR si existen en la jerarquía
  logic [31:0] PC_hier;
  logic [31:0] IR_hier;
  // Protegemos con generate-like conditional: si la jerarquía existe, conectamos; si no, dejamos 0.
  // Muchos simuladores permiten referencias jerárquicas; si fallan, comenta estas líneas.
  // Ajusta las rutas si tus señales internas tienen nombres distintos.
  // Ejemplo de rutas esperadas: DUT.DP.PC, DUT.DP.IR, DUT.ProgIn_i
  // Si no existen, no es crítico: el TB seguirá mostrando periféricos y salidas top-level.

  // Intentar asignaciones jerárquicas con 'ifdef' style protection is not portable;
  // en la práctica, si tu simulador acepta referencias jerárquicas, las siguientes asignaciones funcionarán.
  // Si el simulador falla por jerarquía inexistente, comenta las dos líneas siguientes y usa solo señales top-level.
  assign PC_hier = ( $test$plusargs("use_hier") ) ? DUT.DP.PC : 32'h0;
  assign IR_hier = ( $test$plusargs("use_hier") ) ? DUT.DP.IR : DUT.ProgIn_i;

  // ------------------------
  // Periféricos (extraer flags de 32-bit) - rutas seguras
  // ------------------------
  wire SEG_we = ( $isunknown(DUT.SEG_we) ) ? 1'b0 : DUT.SEG_we;
  wire [31:0] SEG_wdata = ( $isunknown(DUT.SEG_wdata) ) ? 32'h0 : DUT.SEG_wdata;

  wire TEMP_we = ( $isunknown(DUT.TEMP_ctrl_we) ) ? 1'b0 : DUT.TEMP_ctrl_we;
  wire TEMP_done = ( $isunknown(DUT.TEMP_done_rdata) ) ? 1'b0 : DUT.TEMP_done_rdata[0];
  wire [31:0] TEMP_data = ( $isunknown(DUT.TEMP_data_rdata) ) ? 32'h0 : DUT.TEMP_data_rdata;

  wire TIMER_we = ( $isunknown(DUT.TIMER_ctrl_we) ) ? 1'b0 : DUT.TIMER_ctrl_we;
  wire TIMER_done = ( $isunknown(DUT.TIMER_done_rdata) ) ? 1'b0 : DUT.TIMER_done_rdata[0];
  wire [31:0] TIMER_value = ( $isunknown(DUT.TIMER_ctrl_wdata) ) ? 32'h0 : DUT.TIMER_ctrl_wdata;

  // ------------------------
  // Monitores
  // ------------------------
  logic [31:0] last_PC;
  logic last_TEMP_done, last_TIMER_done;
  logic [15:0] last_LED;

  initial begin
    last_PC = 32'hFFFF_FFFF;
    last_TEMP_done = 1'b0;
    last_TIMER_done = 1'b0;
    last_LED = 16'hFFFF;
  end

  always @(posedge clk10) begin
    // ---- PC / instrucciones ----
    if (PC_hier !== last_PC) begin
      last_PC <= PC_hier;
      $display("[%0t] PC=0x%08h  INST=0x%08h  st_dbg=%0d", $time, PC_hier, IR_hier, DUT.st_dbg);
    end

    // ---- Escritura a display ----
    if (SEG_we) begin
      $display("[%0t] DISPLAY <= 0x%02h", $time, SEG_wdata[7:0]);
    end

    // ---- Sensor ----
    if (TEMP_we) begin
      $display("[%0t] TEMP START", $time);
    end

    if (!last_TEMP_done && TEMP_done) begin
      $display("[%0t] TEMP DONE -> DATA = %0d (0x%h)", $time, TEMP_data, TEMP_data);
    end
    last_TEMP_done <= TEMP_done;

    // ---- Timer ----
    if (TIMER_we) begin
      $display("[%0t] TIMER START: limit = %0d (cycles)", $time, TIMER_value);
    end

    if (!last_TIMER_done && TIMER_done) begin
      $display("[%0t] TIMER DONE", $time);
    end
    last_TIMER_done <= TIMER_done;

    // ---- LEDs por cambio ----
    if (LED !== last_LED) begin
      $display("[%0t] LED = %h", $time, LED);
      last_LED <= LED;
    end
  end

  // ------------------------
  // Estímulos
  // ------------------------
  initial begin
    SW    = '0;
    reset = 1'b1;

    // dump para ver señales (opcional)
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);

    wait_clk(10);
    reset = 1'b0;

    $display("================================");
    $display("   SIMULACIÓN INICIADA");
    $display("================================");

    wait_clk(20);

    // --------------------------------
    // Prueba: dejar correr para observar fetch/IR y ejecución de las primeras instrucciones
    // --------------------------------
    $display("\n--- Ejecutando programa en ROM (program.hex) ---");
    wait_clk(200); // ajusta según necesites

    // --------------------------------
    // Fin
    // --------------------------------
    $display("\n================================");
    $display("   FIN DE SIMULACIÓN");
    $display("================================");

    $stop;
  end

endmodule
