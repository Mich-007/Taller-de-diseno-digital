`timescale 1ns/1ps

module Tb_control_unit;

    // --------------------------------------------------------------------
    // Entradas al DUT
    // --------------------------------------------------------------------
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic       Zero;
    logic       less;

    // --------------------------------------------------------------------
    // Salidas del DUT
    // --------------------------------------------------------------------
    logic        RegWrite;
    logic [1:0]  ImmSrc;
    logic        ALUSrc;
    logic        MemWrite;
    logic [1:0]  ResultSrc;
    logic        PCSrc;
    logic [3:0]  ALUControl;
    logic        Jump;

    // --------------------------------------------------------------------
    // Esperados
    // --------------------------------------------------------------------
    logic        exp_RegWrite;
    logic [1:0]  exp_ImmSrc;
    logic        exp_ALUSrc;
    logic        exp_MemWrite;
    logic [1:0]  exp_ResultSrc;
    logic        exp_PCSrc;
    logic [3:0]  exp_ALUControl;
    logic        exp_Jump;

    int errors = 0;

    // --------------------------------------------------------------------
    // Instancia del DUT
    // --------------------------------------------------------------------
    control_unit dut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .Zero(Zero),
        .less(less),
        .RegWrite(RegWrite),
        .ImmSrc(ImmSrc),
        .ALUSrc(ALUSrc),
        .MemWrite(MemWrite),
        .ResultSrc(ResultSrc),
        .PCSrc(PCSrc),
        .ALUControl(ALUControl),
        .Jump(Jump)
    );

    task expected_control_signals_Rtype();
        begin
            exp_RegWrite  = 1;
            exp_ImmSrc    = 2'b00;
            exp_ALUSrc    = 0;
            exp_MemWrite  = 0;
            exp_ResultSrc = 2'b00;
            exp_PCSrc     = 0;
            exp_Jump      = 0;

            // ALUControl depende de funct3/funct7
            if      (funct3 == 3'b000 && funct7 == 7'b0000000) exp_ALUControl = 4'b0000; // ADD
            else if (funct3 == 3'b000 && funct7 == 7'b0100000) exp_ALUControl = 4'b0001; // SUB
            else if (funct3 == 3'b111) exp_ALUControl = 4'b0010; // AND
            else if (funct3 == 3'b110) exp_ALUControl = 4'b0011; // OR
            else                       exp_ALUControl = 4'b0000;
        end
    endtask

    task expected_control_signals_Itype();
        begin
            exp_RegWrite  = 1;
            exp_ImmSrc    = 2'b00;
            exp_ALUSrc    = 1;
            exp_MemWrite  = 0;
            exp_ResultSrc = 2'b00;
            exp_PCSrc     = 0;
            exp_Jump      = 0;
            exp_ALUControl = 4'b0000; // genérico: ADDI
        end
    endtask

    task expected_control_signals_Load();
        begin
            exp_RegWrite  = 1;
            exp_ImmSrc    = 2'b00;
            exp_ALUSrc    = 1;
            exp_MemWrite  = 0;
            exp_ResultSrc = 2'b01;    // viene de memoria
            exp_PCSrc     = 0;
            exp_Jump      = 0;
            exp_ALUControl = 4'b0000; // ADD
        end
    endtask

    task expected_control_signals_Store();
        begin
            exp_RegWrite  = 0;
            exp_ImmSrc    = 2'b01;
            exp_ALUSrc    = 1;
            exp_MemWrite  = 1;
            exp_ResultSrc = 2'b00;
            exp_PCSrc     = 0;
            exp_Jump      = 0;
            exp_ALUControl = 4'b0000; // ADD
        end
    endtask

    task expected_control_signals_Branch();
        begin
            exp_RegWrite  = 0;
            exp_ImmSrc    = 2'b10;
            exp_ALUSrc    = 0;
            exp_MemWrite  = 0;
            exp_ResultSrc = 2'b00;

            // Branch depende de Zero/less
            exp_PCSrc     = Zero; 
            exp_Jump      = 0;

            exp_ALUControl = 4'b0001; // SUB para comparar
        end
    endtask

    task expected_control_signals_JAL();
        begin
            exp_RegWrite  = 1;
            exp_ImmSrc    = 2'b11;
            exp_ALUSrc    = 0;
            exp_MemWrite  = 0;
            exp_ResultSrc = 2'b10; // PC+4
            exp_PCSrc     = 1;
            exp_Jump      = 1;
            exp_ALUControl = 4'b0000;
        end
    endtask

    // --------------------------------------------------------------------
    // Comparación automática
    // --------------------------------------------------------------------
    task check_outputs(string msg);
        begin
            #1;
            if (RegWrite   !== exp_RegWrite  ||
                ImmSrc     !== exp_ImmSrc    ||
                ALUSrc     !== exp_ALUSrc    ||
                MemWrite   !== exp_MemWrite  ||
                ResultSrc  !== exp_ResultSrc ||
                PCSrc      !== exp_PCSrc     ||
                ALUControl !== exp_ALUControl||
                Jump       !== exp_Jump) begin

                $display("ERROR en %s", msg);
                $display("DUT: RW=%b Imm=%b AS=%b MW=%b RS=%b PC=%b ALU=%b JP=%b",
                         RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, PCSrc, ALUControl, Jump);
                $display("EXP: RW=%b Imm=%b AS=%b MW=%b RS=%b PC=%b ALU=%b JP=%b",
                         exp_RegWrite, exp_ImmSrc, exp_ALUSrc, exp_MemWrite, exp_ResultSrc, exp_PCSrc, exp_ALUControl, exp_Jump);
                errors++;
            end
        end
    endtask

    // --------------------------------------------------------------------
    // Secuencia de pruebas
    // --------------------------------------------------------------------
    initial begin

        // --------------------------
        // R-TYPE (ej: ADD)
        // --------------------------
        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0000000;
        Zero = 0; less = 0;
        expected_control_signals_Rtype();
        check_outputs("R-TYPE ADD");

        // SUB
        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0100000;
        expected_control_signals_Rtype();
        check_outputs("R-TYPE SUB");

        // AND
        opcode = 7'b0110011; funct3 = 3'b111; funct7 = 7'b0000000;
        expected_control_signals_Rtype();
        check_outputs("R-TYPE AND");

        // --------------------------
        // I-TYPE (ADDI)
        // --------------------------
        opcode = 7'b0010011; funct3 = 3'b000;
        expected_control_signals_Itype();
        check_outputs("I-TYPE ADDI");

        // --------------------------
        // LOAD (LW)
        // --------------------------
        opcode = 7'b0000011; funct3 = 3'b010;
        expected_control_signals_Load();
        check_outputs("LW");

        // --------------------------
        // STORE (SW)
        // --------------------------
        opcode = 7'b0100011; funct3 = 3'b010;
        expected_control_signals_Store();
        check_outputs("SW");

        // --------------------------
        // BRANCH (BEQ)
        // --------------------------
        opcode = 7'b1100011; funct3 = 3'b000; Zero = 1;
        expected_control_signals_Branch();
        check_outputs("BEQ Zero=1");

        Zero = 0;
        expected_control_signals_Branch();
        check_outputs("BEQ Zero=0");

        // --------------------------
        // JAL
        // --------------------------
        opcode = 7'b1101111;
        expected_control_signals_JAL();
        check_outputs("JAL");

        // RESULTADO FINAL
        if (errors == 0)
            $display("TEST OK: sin errores.");
        else
            $display("TEST FAILED: %0d errores.", errors);

        $finish;
    end

endmodule
