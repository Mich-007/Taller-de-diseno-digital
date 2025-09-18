`timescale 1ns/1ps

// Testbench para register_file
module register_file_tb;

  // Parámetros del diseño
  localparam int N     = 4;             // N: ancho de dirección (2^N registros)
  localparam int W     = 16;            // W: ancho de palabra en bits (ajustable)
  localparam int DEPTH = (1 << N);      // DEPTH: número de registros (2^N)

  // Señales del testbench conectadas al DUT
  logic clk, rst, we;                                    // reloj, reset y write-enable
  logic [N-1:0] addr_rd, addr_rs1, addr_rs2;             // direcciones: addr_rd (write), addr_rs1/rs2 (read)
  logic [W-1:0] data_in, rs1, rs2;                       // data_in (para escribir), salidas rs1/rs2 del DUT

  // Instanciación del DUT (device under test) con parámetros N y W
  register_file #(.N(N), .W(W)) dut (
    .clk(clk),                                           // flanco de reloj síncrono
    .rst(rst),                                           // reset síncrono activo alto
    .we(we),                                             // habilita escritura
    .addr_rd(addr_rd),                                   // dirección de escritura
    .addr_rs1(addr_rs1),                                 // dirección lectura 1
    .addr_rs2(addr_rs2),                                 // dirección lectura 2
    .data_in(data_in),                                   // dato a escribir
    .rs1(rs1),                                           // salida lectura 1
    .rs2(rs2)                                            // salida lectura 2
  );

  // Generador de reloj simple: periodo = 10ns (50 MHz) o #5 ~ 100 MHz según interpretación
  initial clk = 0;                                       // inicializa clk en 0
  always #5 clk = ~clk;                                  // invierte clk cada 5ns => periodo 10ns

  // Generador pseudoaleatorio reproducible (semilla controlada)
  int unsigned seed = 32'hDEAD_BEEF;                     // semilla inicial determinista
  function int unsigned next_rand();                     // función que devuelve un uint aleatorio
    begin
      // Actualiza semilla con constante de mezclado y devuelve $urandom(seed)
      seed = seed + 32'h9E3779B1;                        // mezcla simple para variar semilla
      next_rand = $urandom(seed);                        // devuelve valor pseudoaleatorio
    end
  endfunction

  // Tarea para escribir en el register file de forma sincronizada con el reloj
  task automatic write_reg(input [N-1:0] addr, input [W-1:0] value);
    begin
      @(negedge clk);                                    // esperar flanco negativo antes de cambiar señales
      we      = 1;                                       // activar write enable
      addr_rd = addr;                                    // colocar dirección de escritura
      data_in = value;                                   // colocar dato a escribir
      @(negedge clk);                                    // esperar ciclo para capturar la escritura
      we      = 0;                                       // desactivar write enable
      @(negedge clk);                                    // uno más para estabilizar
    end
  endtask

  // Tarea para configurar direcciones de lectura (las lecturas son combinacionales/síncronas según DUT)
  task automatic read_regs(input [N-1:0] a1, input [N-1:0] a2);
    begin
      addr_rs1 = a1;                                     // setea addr para rs1
      addr_rs2 = a2;                                     // setea addr para rs2
      #1;                                                // pequeña espera para propagar señales
    end
  endtask

  // Bloque inicial principal que realiza las pruebas
  initial begin
    int unsigned expected [DEPTH];                       // array para almacenar valores esperados por dirección
    $display("===== register_file_tb: N=%0d W=%0d DEPTH=%0d =====", N, W, DEPTH);

    // Inicialización de señales
    rst = 1; we = 0; addr_rd = '0; addr_rs1 = '0; addr_rs2 = '0; data_in = '0;
    repeat (4) @(negedge clk);                           // mantener reset unos cuantos ciclos
    rst = 0;                                            // desactivar reset
    @(negedge clk);                                     // esperar un flanco para estabilizar

    // Comprobación de reset: el registro 0 debe ser 0 tras reset
    for (int i = 0; i < DEPTH; i++) begin
      read_regs(i, i);                                  // seleccionar la misma dirección para rs1/rs2
      #1;                                               // esperar propagación
      // Sólo comprobamos el registro 0 explícitamente aquí
      if ((i == 0) && (rs1 !== '0)) $fatal(1, "FAIL: reg0 not zero after reset");
    end
    $display("Reset OK");

    // Escrituras aleatorias a todas las direcciones excepto 0 (reg0 protegido)
    for (int i = 0; i < DEPTH; i++) begin
      if (i == 0) begin
        expected[i] = '0;                                // reg0 debe ser siempre 0
        // intentar escribir a reg0 y comprobar que no cambia
        write_reg(i, {W{1'b1}});                        // intentar escribir todos 1s en reg0
        read_regs(i, i); #1;
        if (rs1 !== '0) $fatal(1, "FAIL: reg0 was written"); // falla si reg0 cambió
      end else begin
        logic [W-1:0] rnd;                              // variable temporal para rnd
        rnd = next_rand();                              // obtener valor pseudoaleatorio reproducible
        expected[i] = rnd;                              // guardar valor esperado en la tabla
        write_reg(i, expected[i]);                      // escribir en la dirección i
      end
    end
    $display("All writes done");

    // Verificación: hacer lecturas aleatorias y comparar con expected[]
    for (int t = 0; t < 512; t++) begin
      int a1 = int(next_rand() % DEPTH);                // dirección aleatoria para rs1
      int a2 = int(next_rand() % DEPTH);                // dirección aleatoria para rs2
      read_regs(a1, a2); #1;                            // aplicar direcciones y esperar
      if (rs1 !== expected[a1]) $fatal(1, "Mismatch rs1 at addr %0d expected %0h got %0h", a1, expected[a1], rs1);
      if (rs2 !== expected[a2]) $fatal(1, "Mismatch rs2 at addr %0d expected %0h got %0h", a2, expected[a2], rs2);
    end

    $display("Random verification OK");

    // Test read-during-write (bypass): comprobar que durante la misma operación de escritura,
    // la lectura de la misma dirección devuelve data_in (si el DUT implementa bypass)
    addr_rs1 = 5; addr_rs2 = 0;                          // preparar direcciones: leer addr 5 y 0
    @(negedge clk);                                      // sincronizar antes de activar write
    we = 1; addr_rd = 5; data_in = 'hA5A5 & ({W{1'b1}}); // activar write con valor conocido (ajustado a W)
    @(posedge clk); #1;                                  // esperar flanco de reloj para efectuar write
    read_regs(5,0); #1;                                  // leer inmediatamente después
    if (rs1 !== ('hA5A5 & ({W{1'b1}}))) $fatal(1, "Bypass fail: expected data_in on rs1 during write");
    we = 0;                                              // desactivar write

    $display("Bypass test OK");

    // Si llegamos hasta aquí, todas las pruebas pasaron
    $display("ALL TESTS PASSED for W=%0d", W);
    $finish;                                             // terminar simulación
  end

endmodule
