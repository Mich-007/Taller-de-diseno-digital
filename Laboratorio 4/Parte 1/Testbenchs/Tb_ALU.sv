`timescale 1ns/1ps

module Tb_ALU;
    localparam XLEN = 32;

    logic [3:0]         ALUControl;
    logic [XLEN-1:0]    A;
    logic [XLEN-1:0]    B;
    logic [XLEN-1:0]    ALUOut;
    logic               Zero;
    logic               less;

    logic [XLEN-1:0]    exp_out;
    logic               exp_zero;
    logic               exp_less;

    int errors = 0;

    ALU #(XLEN) dut (
        .ALUControl(ALUControl),
        .A(A),
        .B(B),
        .ALUOut(ALUOut),
        .Zero(Zero),
        .less(less)
    );

    task compute_expected(input [3:0] ctrl, input [XLEN-1:0] a, b);
        begin
            case (ctrl)
                4'b0000: exp_out = a + b;
                4'b0001: exp_out = a - b;
                4'b0010: exp_out = a & b;
                4'b0011: exp_out = a | b;
                4'b0100: exp_out = a ^ b;
                4'b0101: exp_out = ($signed(a) < $signed(b)) ? 1 : 0;      // SLT
                4'b1001: exp_out = (a < b) ? 1 : 0;                        // SLTU
                4'b0110: exp_out = a >> b[$clog2(XLEN)-1:0];
                4'b0111: exp_out = $signed(a) >>> b[$clog2(XLEN)-1:0];
                4'b1000: exp_out = a << b[$clog2(XLEN)-1:0];
                default: exp_out = 0;
            endcase

            exp_zero = (exp_out == 0);

            exp_less = (ctrl == 4'b0101) ? ($signed(a) < $signed(b))
                                         : (a < b);
        end
    endtask

    task run_test(input [3:0] ctrl, input [XLEN-1:0] a, b);
        begin
            ALUControl = ctrl;
            A = a;
            B = b;
            compute_expected(ctrl, a, b);
            #1;

            if (ALUOut !== exp_out ||
                Zero   !== exp_zero ||
                less   !== exp_less) begin

                $display("ERROR: CTRL=%b A=%0d B=%0d | OUT=%0d EXP=%0d | ZERO=%b EXP=%b | LESS=%b EXP=%b",
                          ctrl, a, b, ALUOut, exp_out, Zero, exp_zero, less, exp_less);
                errors++;
            end
        end
    endtask

    initial begin
        run_test(4'b0000, 10, 5);
        run_test(4'b0001, 10, 5);
        run_test(4'b0010, 10, 5);
        run_test(4'b0011, 10, 5);
        run_test(4'b0100, 10, 5);
        run_test(4'b0101, -3, 5);
        run_test(4'b1001, -3, 5);
        run_test(4'b0110, 64'h1 << 10, 3);
        run_test(4'b0111, -64'd16, 2);
        run_test(4'b1000, 3, 4);

        if (errors == 0)
            $display("TEST OK: sin errores.");
        else
            $display("TEST FAILED: %0d errores.", errors);

        $finish;
    end

endmodule

