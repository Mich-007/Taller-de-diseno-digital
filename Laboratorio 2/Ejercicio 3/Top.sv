// Top.sv
`timescale 1ns/1ps
// Nexys-4: muestra un registro de 16 bits en 7 segmentos y
// lo actualiza con datos pseudoaleatorios desde un LFSR,
// aproximadamente cada 2 segundos (parametrizable).
// Reloj esperado: 100 MHz. Para 2 s -> MAX_COUNT = 200_000_000.

module Top #(
    parameter int unsigned MAX_COUNT = 200_000_000  // 2 s @ 100 MHz
)(
    input  logic        clk_100,
    input  logic        reset,         // Activo en alto (asíncrono en módulos internos)
    input  logic [15:0] SW,            // SW[0] actúa como enable de escritura
    input  logic [3:0]  BTN,           // No usado (reservado)
    output logic [15:0] LED,           // Refleja q
    output logic [7:0]  AN,            // Selectores de dígito (activos en bajo)
    output logic [7:0]  SEG            // {dp, g, f, e, d, c, b, a} activos en bajo
);

    // -----------------------------------------------------------------------------
    // LFSR 16-bit (polinomio x^16 + x^14 + x^13 + x^11 + 1)
    // -----------------------------------------------------------------------------
    logic [15:0] rnd;
    lfsr16 u_lfsr16 (
        .clk    (clk_100),
        .rst    (reset),
        .random (rnd)
    );

    // -----------------------------------------------------------------------------
    // Divisor: genera tick de un ciclo cada MAX_COUNT ciclos (≈ 2 s @ 100 MHz por default)
    // -----------------------------------------------------------------------------
    logic tick;
    clk_div #(.MAX_COUNT(MAX_COUNT)) u_div (
        .clk (clk_100),
        .rst (reset),
        .tick(tick)
    );

    // Pulso de escritura sincronizado y habilitado por SW[0]
    logic tick_d, we_pulse, we;
    always_ff @(posedge clk_100 or posedge reset) begin
        if (reset) begin
            tick_d   <= 1'b0;
            we_pulse <= 1'b0;
        end
        else begin
            tick_d   <= tick;
            we_pulse <=  tick & ~tick_d; // flanco de tick
        end
    end
    assign we = we_pulse & SW[0];

    // -----------------------------------------------------------------------------
    // Registro PIPO de 16 bits
    // -----------------------------------------------------------------------------
    logic [15:0] q;
    reg_pipo #(.WIDTH(16)) u_reg16 (
        .clk (clk_100),
        .rst (reset),
        .we  (we),
        .d   (rnd),
        .q   (q)
    );

    // Mapea q a LEDs para depuración
    assign LED = q;

    // -----------------------------------------------------------------------------
    // Multiplexado del display de 7 segmentos (4 dígitos activos)
    // -----------------------------------------------------------------------------
    logic [19:0] refresh_counter;
    always_ff @(posedge clk_100 or posedge reset) begin
        if (reset) refresh_counter <= '0;
        else       refresh_counter <= refresh_counter + 20'd1;
    end

    logic [3:0] digit;
    always_comb begin
        AN   = 8'hFF; // desactiva todos (activos en bajo)
        unique case (refresh_counter[18:17]) // ~381 Hz por dígito @100 MHz
            2'd0: begin AN[0] = 1'b0; digit = q[3:0];   end
            2'd1: begin AN[1] = 1'b0; digit = q[7:4];   end
            2'd2: begin AN[2] = 1'b0; digit = q[11:8];  end
            2'd3: begin AN[3] = 1'b0; digit = q[15:12]; end
        endcase
    end

    // Decodificador HEX → 7 segmentos (activos en bajo)
    logic [6:0] a_to_g;
    hex7seg u_hex (
        .x      (digit),
        .a_to_g (a_to_g)
    );
    // SEG[7] = dp (apagado = '1' en activo bajo)
    assign SEG = {1'b1, a_to_g}; // {dp,g,f,e,d,c,b,a}

endmodule
