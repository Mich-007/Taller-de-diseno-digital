`timescale 1ns/1ps

module Tb_immgen;

    // --------------------------------------------------------------------
    // Señales del testbench
    // --------------------------------------------------------------------
    logic [31:0] instr_d;      // Instrucción de entrada al DUT
    logic [1:0]  ImmSel;       // Selector de inmediato
    logic [31:0] imm;          // Salida del DUT

    logic [31:0] exp_imm;      // Inmediato esperado

    int errors = 0;

    // --------------------------------------------------------------------
    // Instanciación del DUT
    // --------------------------------------------------------------------
    immgen_rv32 dut (
        .instr_d(instr_d),
        .ImmSel(ImmSel),
        .imm(imm)
    );

    // --------------------------------------------------------------------
    // Tarea: calcular valor esperado
    // --------------------------------------------------------------------
    task compute_expected(input [31:0] ins, input [1:0] sel);
        begin
            case (sel)
                2'b00:  exp_imm = {{20{ins[31]}}, ins[31:20]};                                   // I
                2'b01:  exp_imm = {{20{ins[31]}}, ins[31:25], ins[11:7]};                        // S
                2'b10:  exp_imm = {{19{ins[31]}}, ins[31], ins[7], ins[30:25], ins[11:8], 1'b0}; // SB
                2'b11:  exp_imm = {{11{ins[31]}}, ins[31], ins[19:12], ins[20], ins[30:21], 1'b0}; // J
                default: exp_imm = 32'h0;
            endcase
        end
    endtask

    // --------------------------------------------------------------------
    // Tarea: ejecutar un test
    // --------------------------------------------------------------------
    task run_test(input [31:0] ins, input [1:0] sel);
        begin
            instr_d = ins;
            ImmSel  = sel;

            compute_expected(ins, sel);
            #1;

            if (imm !== exp_imm) begin
                $display("ERROR: instr=%h ImmSel=%b | OUT=%h EXP=%h",
                          ins, sel, imm, exp_imm);
                errors++;
            end
        end
    endtask

    // --------------------------------------------------------------------
    // Secuencia de pruebas
    // --------------------------------------------------------------------
    initial begin
        // Instrucciones arbitrarias para verificar extracción de campos
        run_test(32'hFFF0A123, 2'b00);  // I-type
        run_test(32'h00F12023, 2'b01);  // S-type
        run_test(32'hFE000EE3, 2'b10);  // SB-type (branch)
        run_test(32'hFF0000EF, 2'b11);  // J-type (jal)

        run_test(32'h00450693, 2'b00);  // addi x13,x10,4
        run_test(32'h00B50423, 2'b01);  // sw x11,0(x10)
        run_test(32'hFE551CE3, 2'b10);  // bne x10,x5,offset
        run_test(32'h0020006F, 2'b11);  // jal x0,2

        if (errors == 0)
            $display("TEST OK: sin errores.");
        else
            $display("TEST FAILED: %0d errores.", errors);

        $finish;
    end

endmodule
