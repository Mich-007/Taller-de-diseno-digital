// register_file_tb.sv
// Testbench para banco de registros parametrizable
// Verifica:
// - Escritura controlada por 'we'
// - Lectura coherente desde dos salidas
// - Protección del registro 0
// - Reset funcional
// - Comportamiento esperado en bypass y escritura múltiple

`timescale 1ns/1ps

module register_file_tb;

  // ________________________________________________________________________________
  // 1. Parámetros del diseño
  // ________________________________________________________________________________
  localparam int N     = 4;             // N bits de dirección → 2ⁿ registros
  localparam int W     = 16;            // W bits de ancho de palabra
  localparam int DEPTH = 2 ** N;        // Número total de registros

  // ________________________________________________________________________________
  // 2. Señales de prueba (inputs/outputs del DUT)
  // ________________________________________________________________________________
  logic clk, rst, we;
  logic [N-1:0] addr_rd, addr_rs1, addr_rs2;
  logic [W-1:0] data_in, rs1, rs2;

  // ________________________________________________________________________________
  // 3. Instancia del DUT (Device Under Test)
  // ________________________________________________________________________________
  register_file #(.N(N), .W(W)) dut (
    .clk(clk),
    .rst(rst),
    .we(we),

    //Direccion
    .addr_rd(addr_rd),
    .addr_rs1(addr_rs1),
    .addr_rs2(addr_rs2),

    //Datos
    .data_in(data_in),

    //Salidas
    .rs1(rs1),
    .rs2(rs2)
  );

  // ________________________________________________________________________________
  // 4. Generación de reloj 
  // ________________________________________________________________________________
  always #5 clk = ~clk;

  // ________________________________________________________________________________
  // 5. Tareas auxiliares para simplificar escritura y lectura
  // ________________________________________________________________________________

  // Tarea para escribir un valor en un registro específico
  // Solo se ejecuta si 'we' está en alto durante flanco positivo
  task automatic write_reg(input [N-1:0] addr, input [W-1:0] value);
    begin
      @(negedge clk);
      we      = 1;
      addr_rd = addr;
      data_in = value;
      @(negedge clk);
      we      = 0;
    end
  endtask

  // Tarea para leer dos registros simultáneamente
  // Se usa lógica combinacional, no requiere flanco de reloj
  task automatic read_regs(input [N-1:0] addr1, input [N-1:0] addr2);
    begin
      addr_rs1 = addr1;
      addr_rs2 = addr2;
      #1; // pequeña espera para propagación
      $display("Read rs1[r%0d]=%0h, rs2[r%0d]=%0h", addr1, rs1, addr2, rs2);
    end
  endtask

  // ________________________________________________________________________________
  // 6. Secuencia de pruebas
  // ________________________________________________________________________________
  initial begin
    $display("===============  BANCO DE REGISTROS ===============");
    clk = 0; rst = 1; we = 0;
    addr_rd = 0; addr_rs1 = 0; addr_rs2 = 0; data_in = 0;

    // ________________________________________________________________________________
    // Reset inicial: todos los registros deben quedar en cero
    // ________________________________________________________________________________
    repeat (2) @(negedge clk);
    rst = 0;
    $display("Reset liberado");

    // ________________________________________________________________________________
    // Test 1: Verificar que el registro 0 es de solo lectura
    // ________________________________________________________________________________
    write_reg(0, 16'hABCD);  // intento escribir en reg0
    read_regs(0, 0);         // debe devolver 0000 en ambas salidas

    // ________________________________________________________________________________
    // Test 2: Escritura en reg1 y reg2, luego lectura
    // ________________________________________________________________________________
    write_reg(1, 16'h1234);
    write_reg(2, 16'h5678);
    read_regs(1, 2);         // rs1=1234, rs2=5678

    // ________________________________________________________________________________
    // Test 3: Escritura y lectura simultánea
    // ________________________________________________________________________________
    addr_rs1 = 3;            // leer reg3
    addr_rs2 = 0;            // leer reg0
    @(negedge clk);
    we      = 1;
    addr_rd = 3;
    data_in = 16'hAAAA;
    @(posedge clk);          // escritura ocurre aquí
    #1;
    read_regs(3, 0);         // rs1=AAAA, rs2=0000
    we = 0;

    // ________________________________________________________________________________
    // Test 4: Sobrescribir reg1 con nuevo valor
    // ________________________________________________________________________________
    write_reg(1, 16'hDEAD);
    read_regs(1, 2);         // rs1=DEAD, rs2=5678

    // ________________________________________________________________________________
    // Test 5: Aplicar reset en medio de simulación
    // ________________________________________________________________________________
    rst = 1;
    @(negedge clk);
    rst = 0;
    $display("Reset aplicado, registros deben estar en 0");
    read_regs(1, 2);         // rs1=0000, rs2=0000

    // ________________________________________________________________________________
    // Test 6: Escritura en varios registros (stress test)
    // ------------------------------------------------------------
    for (int i = 1; i < 8; i++) begin
      write_reg(i, i * 16'h1111); // valores crecientes
      read_regs(i, i-1);          // verificar escritura y lectura previa
    end

    // ________________________________________________________________________________
    // Test 7: Verificar que no se escribe si 'we' está en bajo
    // ________________________________________________________________________________
    @(negedge clk);
    we      = 0;             // escritura deshabilitada
    addr_rd = 9;
    data_in = 16'hBEEF;
    @(posedge clk);          // no debe escribirse
    #1;
    addr_rs1 = 9;
    addr_rs2 = 0;
    read_regs(9, 0);         // rs1 debe ser 0000, no BEEF

    $display("________________________________________________________________________________");
    $finish;
  end

endmodule
