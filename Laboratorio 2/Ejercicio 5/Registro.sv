module Registro #(
  parameter int N = 32       // 1 en TB, 0 en FPGA
)(
  input  logic        clk, reset,leer_ahora,
  // escritura
  input  logic        REGiniciar,
  input  logic [15:0]  nuevo_dato,
  // lectura por índice
  input  logic [4:0]  leer_index,
  output logic [15:0]  leer_data,
  // estado (opcional, útil para "playback")
  output logic [4:0]  REGposicion,
  output logic [5:0]  REGContador,   // 0..N
  output logic valor_leer_listo
);

  logic [15:0] memoria [0:N-1];
  logic [4:0]  posicion;
  logic [5:0]  Contador;
  int i;

  // escritura circular + conteo saturado
    always_ff @(posedge clk or posedge reset) begin    
        if (reset) begin
            posicion <= '0;
            Contador  <= '0;
        for (i = 0; i < N; i++) memoria[i] <= 8'h00;
        end else if (REGiniciar) begin
            memoria[posicion] <= nuevo_dato;
            posicion <= (posicion == N-1) ? 5'd0 : posicion + 5'd1;
        if (Contador < N) Contador <= Contador + 6'd1;
        end
    end
  
    assign REGposicion = posicion;
    assign REGContador = Contador;
  // lectura simple por índice (combinacional)
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            leer_data <= 8'h00;
            valor_leer_listo  <= 1'b0;
        end else begin
            valor_leer_listo  <= leer_ahora;                 // válido 1 ciclo después
            if (leer_ahora) leer_data <= memoria[leer_index];
        end
    end
  
endmodule


