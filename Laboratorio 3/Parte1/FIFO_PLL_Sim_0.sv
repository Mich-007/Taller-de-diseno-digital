`timescale 1ns / 1ps

module FIFO_PLL_Sim_0;
logic clk;
logic clk_16MHz;
logic rst;
logic rd_en;
logic wr_en;
logic [7:0] data_in;
logic [7:0] data_out;
logic full;
logic empty;
logic locked;
logic [8:0] data_count;

// ------------------------------
// Instancia del FIFO y PLL
// ------------------------------
FIFO_Block uut (
    .clk(clk),
    .clk_16MHz(clk_16MHz),
    .rst(rst),
    .rd_en(rd_en),
    .wr_en(wr_en),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty),
    .locked(locked),
    .data_count_0(data_count)
);

// ------------------------------
// Generador de reloj (100 MHz)
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Comienzo de simulacion
initial begin
    // Inicialización
    rst = 1;
    rd_en = 0;
    wr_en = 0;
    data_in = 8'd0;

    // Esperar señal locked
    #10;
    rst = 0;
    wait(locked);
    #20;

    // Escritura completa: llenar los 512 espacios
    $display("---- Comenzando llenado del FIFO ----");
    repeat (512) begin
        @(posedge clk_16MHz);
        if (!full) begin
            wr_en = 1;
            data_in = data_in + 1;
        end else begin
            wr_en = 0;
            $display("FIFO lleno en tiempo %0t, data_count=%0d", $time, data_count);
        end
    end
    @(posedge clk_16MHz);
    wr_en = 0;
    $display("Llenado completo. full=%b, data_count=%0d", full, data_count);

    // Intento de escritura extra
    @(posedge clk_16MHz);
    wr_en = 1;
    data_in = data_in + 1;
    #10;
    wr_en = 0;
    $display("Intento de escribir cuando full=%b", full);

    // Lectura 
    $display("---- Comenzando lectura del FIFO ----");
    repeat (513) begin
        @(posedge clk_16MHz);
        if (!empty) rd_en = 1;
        else rd_en = 0;
    end
    rd_en = 0;
    $display("Lectura parcial. full=%b, data_count=%0d", full, data_count);

    // Esperar un poco y detener simulación
    #100;
    $finish;
end

endmodule
