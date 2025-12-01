`timescale 1ns/1ps

// ===============================================================
// TESTBENCH para TOP con Sensor + Timer + Display
// ===============================================================
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
  // Instancia del DUT
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
  // Acceso al reloj interno
  // (en Simulación = clk)
  // ------------------------
  wire clk10 = DUT.clk_10MHz;

  task wait_clk(input int n);
    repeat(n) @(posedge clk10);
  endtask

  // ------------------------
  // Pinchar señales internas
  // ------------------------

  // CPU
  wire [31:0] PC   = DUT.DP.PC;
  wire [31:0] INST = DUT.ProgIn_i;

  // Periféricos
  wire SEG_we              = DUT.SEG_we;
  wire [31:0] SEG_wdata   = DUT.SEG_wdata;

  wire TEMP_we             = DUT.TEMP_ctrl_we;
  wire TEMP_done           = DUT.TEMP_done_rdata;
  wire [31:0] TEMP_data   = DUT.TEMP_data_rdata;

  wire TIMER_we            = DUT.TIMER_ctrl_we;
  wire TIMER_done          = DUT.TIMER_done_rdata;
  wire [31:0] TIMER_value = DUT.TIMER_ctrl_wdata;

  // ------------------------
  // Monitores
  // ------------------------

  logic [31:0] last_PC;
  logic last_TEMP_done, last_TIMER_done;

  always @(posedge clk10) begin

    // ---- PC / instrucciones ----
    if (PC != last_PC) begin
      last_PC <= PC;
      $display("[%0t] PC=0x%08h  INST=0x%08h", $time, PC, INST);
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
      $display("[%0t] TEMP DONE -> DATA = %0d (0x%h)",
                 $time, TEMP_data, TEMP_data);
    end
    last_TEMP_done <= TEMP_done;

    // ---- Timer ----
    if (TIMER_we) begin
      $display("[%0t] TIMER START: %0d segundos",
                $time, TIMER_value);
    end

    if (!last_TIMER_done && TIMER_done) begin
      $display("[%0t] TIMER DONE", $time);
    end
    last_TIMER_done <= TIMER_done;

    // ---- LEDs directos ----
    if (LED !== 'x)
      $display("[%0t] LED = %h", $time, LED);

  end


  // ------------------------
  // Estímulos
  // ------------------------
  initial begin

    SW    = '0;
    reset = 1'b1;

    wait_clk(10);
    reset = 1'b0;

    $display("================================");
    $display("   SIMULACIÓN INICIADA");
    $display("================================");

    wait_clk(20);

    // --------------------------------
    // Modo: seleccionar 1 segundo
    // (ejemplo: switch 0 = 1 s)
    // --------------------------------
    $display("\n--- Seleccionando 1 segundo ---");
    SW = 16'h0001;
    wait_clk(20);
    SW = 16'h0000;

    // esperar que el flujo completo ocurra:
    // temp -> display -> timer
    wait_clk(10000);

    // --------------------------------
    // Modo: seleccionar 5 segundos
    // --------------------------------
    $display("\n--- Seleccionando 5 segundos ---");
    SW = 16'h0004;
    wait_clk(20);
    SW = 16'h0000;

    wait_clk(20000);

    // --------------------------------
    // Fin
    // --------------------------------
    $display("\n================================");
    $display("   FIN DE SIMULACIÓN");
    $display("================================");

    $stop;
  end

endmodule

