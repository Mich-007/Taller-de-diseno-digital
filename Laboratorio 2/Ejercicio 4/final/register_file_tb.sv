`timescale 1ns/1ps

module register_file_tb;

  // Parámetros del diseño
  localparam int N     = 4;             // N bits de dirección → 2^N registros
  localparam int W     = 16;            // W bits de ancho de palabra (cambiar a 8 en otra corrida)
  localparam int DEPTH = (1 << N);      // Número total de registros

  // Señales
  logic clk, rst, we;
  logic [N-1:0] addr_rd, addr_rs1, addr_rs2;
  logic [W-1:0] data_in, rs1, rs2;

  // DUT
  register_file #(.N(N), .W(W)) dut (
    .clk(clk),
    .rst(rst),
    .we(we),
    .addr_rd(addr_rd),
    .addr_rs1(addr_rs1),
    .addr_rs2(addr_rs2),
    .data_in(data_in),
    .rs1(rs1),
    .rs2(rs2)
  );

  // reloj
  initial clk = 0;
  always #5 clk = ~clk;

  // Generador de números reproducible con semilla controlada
  int unsigned seed = 32'hDEAD_BEEF;
  function int unsigned next_rand();
    begin
      // actualiza la semilla y devuelve nuevo valor pseudoaleatorio
      // este patrón es portable para simuladores SystemVerilog que soportan $urandom
      seed = seed + 32'h9E3779B1; // mezcla simple para variar semilla entre llamadas
      next_rand = $urandom(seed);
    end
  endfunction

  // helpers para write/read
  task automatic write_reg(input [N-1:0] addr, input [W-1:0] value);
    begin
      @(negedge clk);
      we      = 1;
      addr_rd = addr;
      data_in = value;
      @(negedge clk);
      we      = 0;
      @(negedge clk);
    end
  endtask

  task automatic read_regs(input [N-1:0] a1, input [N-1:0] a2);
    begin
      addr_rs1 = a1;
      addr_rs2 = a2;
      #1;
    end
  endtask

  initial begin
    int unsigned expected [DEPTH];
    $display("===== register_file_tb: N=%0d W=%0d DEPTH=%0d =====", N, W, DEPTH);

    // init
    rst = 1; we = 0; addr_rd = '0; addr_rs1 = '0; addr_rs2 = '0; data_in = '0;
    repeat (4) @(negedge clk);
    rst = 0;
    @(negedge clk);

    // reset check: all zeros
    for (int i = 0; i < DEPTH; i++) begin
      read_regs(i, i);
      #1;
      if ((i == 0) && (rs1 !== '0)) $fatal("FAIL: reg0 not zero after reset");
    end
    $display("Reset OK");

    // Escritura aleatoria a todas las direcciones (excepto 0)
    for (int i = 0; i < DEPTH; i++) begin
      if (i == 0) begin
        expected[i] = '0;
        // intentar escribir valor distinto y comprobar que reg0 no cambia
        write_reg(i, {W{1'b1}});
        read_regs(i, i);
        #1;
        if (rs1 !== '0) $fatal("FAIL: reg0 was written");
      end else begin
        logic [W-1:0] rnd;
        rnd = next_rand();          // genera valor reproducible
        expected[i] = rnd;
        write_reg(i, expected[i]);
      end
    end
    $display("All writes done");

    // Verificación: lecturas aleatorias comprobadas (usa next_rand y modulo DEPTH)
    for (int t = 0; t < 512; t++) begin
      int a1 = int(next_rand() % DEPTH);
      int a2 = int(next_rand() % DEPTH);
      read_regs(a1, a2);
      #1;
      if (rs1 !== expected[a1]) $fatal("Mismatch rs1 at addr %0d expected %0h got %0h", a1, expected[a1], rs1);
      if (rs2 !== expected[a2]) $fatal("Mismatch rs2 at addr %0d expected %0h got %0h", a2, expected[a2], rs2);
    end

    $display("Random verification OK");

    // Test read-during-write (bypass)
    addr_rs1 = 5; addr_rs2 = 0;
    @(negedge clk);
    we = 1; addr_rd = 5; data_in = 'hA5A5 & ({W{1'b1}});
    @(posedge clk); #1;
    read_regs(5,0); #1;
    if (rs1 !== ('hA5A5 & ({W{1'b1}}))) $fatal("Bypass fail: expected data_in on rs1 during write");
    we = 0;

    $display("Bypass test OK");

    $display("ALL TESTS PASSED for W=%0d", W);
    $finish;
  end

endmodule
