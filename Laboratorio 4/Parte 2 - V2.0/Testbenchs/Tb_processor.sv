`timescale 1ns/1ps

module Tb_processor;

  localparam XLEN = 32;

  // Señales DUT
  logic clk, rst;
  logic [XLEN-1:0] ProgAddress;
  logic [XLEN-1:0] ProgIn;
  logic [XLEN-1:0] DataIn;
  logic [XLEN-1:0] DataAddress;
  logic [XLEN-1:0] DataOut;
  logic we;

  // Reloj
  always #5 clk = ~clk;

  // Modelo ROM mínimo (solo entrega datos según dirección)
  function automatic [XLEN-1:0] fake_rom(input logic [XLEN-1:0] addr);
    // Programa mínimo:
    // PC=0x00 -> ADDI x1, x0, 5
    // PC=0x04 -> ADDI x2, x1, 3
    // PC=0x08 -> BEQ  x1, x2, +8
    // PC=0x0C -> ADDI x3, x0, 9
    // PC=0x10 -> SLLI x4, x3, 1
    case(addr)
      32'h00: fake_rom = 32'h00500093; // addi x1,x0,5
      32'h04: fake_rom = 32'h00308113; // addi x2,x1,3
      32'h08: fake_rom = 32'h00208263; // beq x1,x2,PC+8
      32'h0C: fake_rom = 32'h00900193; // addi x3,x0,9
      32'h10: fake_rom = 32'h00119213; // slli x4,x3,1
      default: fake_rom = 32'h0000006f; // jal x0, 0
    endcase
  endfunction

  // Modelo RAM mínimo (solo lectura fija)
  function automatic [XLEN-1:0] fake_ram(input logic [XLEN-1:0] addr);
    fake_ram = 32'hA5A55A5A; // valor fijo para pruebas
  endfunction

  // DUT
  RISCV_Processor #(.XLEN(XLEN)) DUT(
      .clk_i(clk),
      .rst_i(rst),
      .ProgAddress_o(ProgAddress),
      .ProgIn_i(ProgIn),
      .DataIn_i(DataIn),
      .DataAddress_o(DataAddress),
      .DataOut_o(DataOut),
      .we_o(we)
  );

  // Aplicación del entorno
  initial begin
    clk = 0;
    rst = 1;
    repeat(3) @(posedge clk);
    rst = 0;
  end

  // Alimentar ROM
  always_comb ProgIn = fake_rom(ProgAddress);

  // Alimentar RAM
  always_comb DataIn = fake_ram(DataAddress);

  // Autoverificación
  initial begin
    @(negedge rst);

    // Esperar a que ejecute varias instrucciones
    repeat(5) @(posedge clk);

    // Verificaciones mínimas (solo PC observable indirectamente)
    if (ProgAddress != 32'h14) begin
      $error("PC incorrecto. PC=%h, esperado 0x14 después de ejecutar secuencia.", ProgAddress);
    end else begin
      $display("PC OK");
    end

    // Verificación de escritura
    if (we !== 1'b0) begin
      $error("Señal we debe ser 0 en esta prueba (no hay stores en ROM).");
    end else begin
      $display("we OK");
    end

    $display("Fin de prueba.");
    $finish;
  end

endmodule

