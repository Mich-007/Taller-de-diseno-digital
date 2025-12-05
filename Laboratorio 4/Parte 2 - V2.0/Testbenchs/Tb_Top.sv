`timescale 1ns/1ps

module Top_tb;

    // =======================
    // Señales del testbench
    // =======================
    logic clk;
    logic rst;
    logic [15:0] SW;

    wire [6:0] SEG;
    wire [7:0] AN;
    wire [15:0] LED;

    wire SCL;
    tri  SDA;

    // Driver interno para SDA (para simular el ADT7420)
    logic SDA_drv; 
    assign SDA = SDA_drv ? 1'b0 : 1'bz;

    // =======================
    // DUT
    // =======================
    Top dut (
        .clk(clk),
        .rst(rst),
        .SW(SW),
        .SEG(SEG),
        .AN(AN),
        .LED(LED),
        .SCL(SCL),
        .SDA(SDA)
    );

    // =======================
    // Generación de reloj
    // =======================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 100 MHz
    end

    // =======================
    // Estímulos
    // =======================
    initial begin
        // Inicialización
        rst = 1;
        SW  = 16'h0000;

        SDA_drv = 0;  // SDA en alta impedancia

        repeat(5) @(posedge clk);
        rst = 0;

        // ============================
        // Test 1: switch básicos
        // ============================
        @(posedge clk);
        SW = 16'h0001;

        repeat(200) @(posedge clk);

        // ============================
        // Test 2: Simular respuesta del ADT7420
        // SDA se maneja con open-drain
        // ============================
        force SDA_drv = 1;     // Pull SDA LOW (ACK)
        #200;
        release SDA_drv;       // Z (dejar libre)

        // Simular envío de un bit "0"
        force SDA_drv = 1;
        #200;
        release SDA_drv;

        // Simular envío de un bit "1"
        // (dejar en Z)
        #200;

        repeat(5000) @(posedge clk);

        $finish;
    end

endmodule