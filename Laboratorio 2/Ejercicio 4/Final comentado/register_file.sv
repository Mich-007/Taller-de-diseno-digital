// ============================================================
// register_file.sv
// Banco de registros parametrizable con lectura doble
// - 2^N registros, ancho W
// - Escritura controlada por we
// - Registro 0 protegido (siempre 0)
// - Bypass read-after-write definido
// ============================================================

module register_file #(
  parameter int N = 4,   // N: número de bits de dirección -> 2^N entradas en el banco
  parameter int W = 8    // W: ancho en bits de cada palabra
)(
  input  logic             clk,        // reloj síncrono del sistema, flanco positivo usado para escribir
  input  logic             rst,        // reset síncrono activo alto: pone todos los registros a 0
  input  logic             we,         // write enable: cuando es 1 en el flanco de reloj se escribe data_in en addr_rd
  input  logic [N-1:0]     addr_rd,    // dirección de escritura (N bits)
  input  logic [N-1:0]     addr_rs1,   // dirección de lectura 1 (N bits)
  input  logic [N-1:0]     addr_rs2,   // dirección de lectura 2 (N bits)
  input  logic [W-1:0]     data_in,    // dato a escribir cuando we = 1
  output logic [W-1:0]     rs1,        // salida de lectura 1 (valor leído en addr_rs1)
  output logic [W-1:0]     rs2         // salida de lectura 2 (valor leído en addr_rs2)
);

  // DEPTH es número total de registros: 2^N
  localparam int DEPTH = (1 << N);

  // arreglo de registros, cada entrada tiene W bits
  // regs[0] ... regs[DEPTH-1]
  logic [W-1:0] regs [0:DEPTH-1];

  // Escritura síncrona con reset síncrono
  // - Se usa always_ff para describir comportamiento en el flanco de reloj
  // - En rst se limpian todos los registros a 0
  // - Si no hay rst y we=1 y la dirección no es cero, se escribe data_in en regs[addr_rd]
  always_ff @(posedge clk) begin
    if (rst) begin
      // Bucle para inicializar todos los registros a cero bajo reset
      for (int i = 0; i < DEPTH; i = i + 1) regs[i] <= '0;
    end else begin
      // Escritura protegida: no escribir en el registro 0 (registro hardwired a cero)
      // Comprueba we y que addr_rd != 0 antes de escribir
      if (we && (addr_rd != '0)) regs[addr_rd] <= data_in;
    end
  end

  // Lectura combinacional con bypass (read-after-write)
  // - Se describe en always_comb para que las salidas rs1/rs2 cambien inmediatamente
  // - Política:
  //   * Si la dirección de lectura es 0 => salida 0 (registro 0 siempre devuelve 0)
  //   * Si hay una escritura en curso (we==1) y la dirección de lectura coincide con addr_rd
  //     y addr_rd != 0 => devolver data_in (bypass), es decir, ver el dato que se está escribiendo
  //   * En otro caso devolver el valor almacenado en regs[addr]
  always_comb begin
    // rs1: lógica de selección para lectura1
    if (addr_rs1 == '0)                         // si se lee desde registro 0
      rs1 = '0;                                 // devolver 0 (protección de reg0)
    else if (we && (addr_rs1 == addr_rd) && (addr_rd != '0)) // si hay escrit. y direcciones coinciden
      rs1 = data_in;                            // bypass: devolver el dato que se está escribiendo
    else
      rs1 = regs[addr_rs1];                     // caso normal: devolver valor almacenado

    // rs2: misma lógica aplicada para la segunda lectura
    if (addr_rs2 == '0)                         // si se lee desde registro 0
      rs2 = '0;                                 // devolver 0
    else if (we && (addr_rs2 == addr_rd) && (addr_rd != '0)) // chequeo de bypass para rs2
      rs2 = data_in;                            // devolver dato en writethrough
    else
      rs2 = regs[addr_rs2];                     // devolver valor almacenado
  end

endmodule
