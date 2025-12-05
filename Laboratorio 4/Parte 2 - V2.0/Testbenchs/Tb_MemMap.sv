`timescale 1ns/1ps

module Tb_MemMap;

    // ============================
    // Señales del DUT
    // ============================
    logic clk;
    logic [31:0] DataAddress_o, DataOut_o;
    logic MemWrite;
    logic [31:0] DataIn_i;

    logic RAM_we;
    logic [31:0] RAM_addr, RAM_wdata;
    logic [31:0] RAM_rdata;

    logic [31:0] SW_rdata;

    logic [31:0] LED_wdata;
    logic LED_we;

    logic [31:0] SEG_wdata;
    logic SEG_we;

    logic [31:0] TIMER_ctrl_wdata;
    logic TIMER_ctrl_we;
    logic [31:0] TIMER_done_rdata;

    logic [31:0] TEMP_ctrl_wdata;
    logic TEMP_ctrl_we;
    logic [31:0] TEMP_data_rdata;

    // ============================
    // Generador de reloj
    // ============================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ============================
    // DUT
    // ============================
    MemMap MEM1(
        .DataAddress_o(DataAddress_o),
        .DataOut_o(DataOut_o),
        .MemWrite(MemWrite),
        .DataIn_i(DataIn_i),

        .RAM_we(RAM_we),
        .RAM_addr(RAM_addr),
        .RAM_wdata(RAM_wdata),
        .RAM_rdata(RAM_rdata),

        .SW_rdata(SW_rdata),

        .LED_wdata(LED_wdata),
        .LED_we(LED_we),

        .SEG_wdata(SEG_wdata),
        .SEG_we(SEG_we),

        .TIMER_ctrl_wdata(TIMER_ctrl_wdata),
        .TIMER_ctrl_we(TIMER_ctrl_we),
        .TIMER_done_rdata(TIMER_done_rdata),

        .TEMP_ctrl_wdata(TEMP_ctrl_wdata),
        .TEMP_ctrl_we(TEMP_ctrl_we),
        .TEMP_data_rdata(TEMP_data_rdata)
    );

    // ============================
    // TEST AUTOMÁTICO
    // ============================
    initial begin
        $display("=== INICIO TEST MEMMAP ===");

        MemWrite = 0;
        RAM_rdata       = 32'hAAAA_AAAA;
        SW_rdata        = 32'hBBBB_BBBB;
        TIMER_done_rdata = 32'hCCCC_CCCC;
        TEMP_data_rdata  = 32'hDDDD_DDDD;

        // ============================
        // TEST 1: Escritura en RAM
        // ============================
        DataAddress_o = 32'h0000_1000;   // Inicio RAM
        DataOut_o     = 32'h12345678;
        MemWrite      = 1;
        #1;

        if (RAM_we !== 1 || RAM_addr !== 32'h0000_1000 || RAM_wdata !== 32'h12345678)
            $error("ERROR: Escritura RAM incorrecta");
        else
            $display("OK: Escritura RAM correcta");

        // ============================
        // TEST 2: Lectura desde RAM
        // ============================
        MemWrite = 0;
        #1;

        if (DataIn_i !== 32'hAAAA_AAAA)
            $error("ERROR: Lectura RAM incorrecta");
        else
            $display("OK: Lectura RAM correcta");

        // ============================
        // TEST 3: Lectura desde SW
        // ============================
        DataAddress_o = 32'h0000_2000; // SW
        #1;

        if (DataIn_i !== 32'hBBBB_BBBB)
            $error("ERROR: Lectura SW incorrecta");
        else
            $display("OK: Lectura SW correcta");

        // ============================
        // TEST 4: Escritura LED
        // ============================
        DataAddress_o = 32'h0000_2004;
        DataOut_o     = 32'hFACEFACE;
        MemWrite      = 1;
        #1;

        if (!LED_we || LED_wdata != 32'hFACEFACE)
            $error("ERROR: Escritura LED incorrecta");
        else
            $display("OK: Escritura LED correcta");

        // ============================
        // TEST 5: Lectura TIMER DONE
        // ============================
        MemWrite = 0;
        DataAddress_o = 32'h0000_201C;
        #1;

        if (DataIn_i != 32'hCCCC_CCCC)
            $error("ERROR: TIMER DONE incorrecto");
        else
            $display("OK: TIMER DONE correcto");

        // ============================
        // TEST 6: Lectura TEMP DATA
        // ============================
        DataAddress_o = 32'h0000_2034;
        #1;

        if (DataIn_i != 32'hDDDD_DDDD)
            $error("ERROR: TEMP DATA incorrecto");
        else
            $display("OK: TEMP DATA correcto");

        // ============================
        // TEST 7: Dirección inválida
        // ============================
        DataAddress_o = 32'h0000_9999;
        #1;

        if (DataIn_i != 32'h0000_0000)
            $error("ERROR: Dirección desconocida debería retornar 0");
        else
            $display("OK: Dirección desconocida correcta");

        // ============================
        // FIN
        // ============================
        $display("=== FIN TEST MEMMAP ===");
        $finish;
    end
endmodule
