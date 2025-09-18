`timescale 1ns/1ps

module tb_comparacion_RCA_VS_CLA;
    // Entradas comunes
    logic [15:0] a, b;
    logic cin;

    // Salidas RCA
    logic [15:0] sum_rca;
    logic cout_rca;

    // Salidas CLA
    logic [15:0] sum_cla;
    logic cout_cla;

    // Resultado esperado
    logic [16:0] expected;

    // Se instancia el Ripple-Carry Adder
    RCA_parametrizable #(.N(16)) rca (
        .A(a),
        .B(b),
        .Cin(cin),
        .Sum(sum_rca),
        .Cout(cout_rca)
    );

    // Instanciamos el Carry-Lookahead Adder
    CLA_16bits cla (
        .A(a),
        .B(b),
        .Cin(cin),
        .Sum(sum_cla),
        .Cout(cout_cla)
    );

    // Generador de estímulos
    initial begin
        $display("=== Comparación RCA vs CLA (16 bits) ===");

        // Pruebas determinadas
        a = 16'h0000; b = 16'h0000; cin = 0; #10 check_results();
        a = 16'hFFFF; b = 16'h0001; cin = 0; #10 check_results();
        a = 16'hAAAA; b = 16'h5555; cin = 1; #10 check_results();

        // Pruebas aleatorias
        repeat (20) begin
            a   = $urandom();
            b   = $urandom();
            cin = $urandom_range(0,1);
            #10 check_results();
        end

        $display("=== Fin de la simulación ===");
        $finish;
    end

    // Tarea para verificar resultados
    task check_results();
        begin
            expected = a + b + cin;
            
            //Verificando Ripple-Carry Adder
            if (({cout_rca, sum_rca} !== expected)) begin
                $display("[ERROR] RCA fallo: a=%h b=%h cin=%b -> RCA={%b,%h} esperado=%h",
                         a, b, cin, cout_rca, sum_rca, expected);
            end else begin
                $display("[OK] RCA correcto: a=%h b=%h cin=%b -> sum=%h cout=%b",
                         a, b, cin, sum_rca, cout_rca);
            end
            
            // Verificando CarryLookahead Adder
            if (({cout_cla, sum_cla} !== expected)) begin
                $display("[ERROR] CLA fallo: a=%h b=%h cin=%b -> CLA={%b,%h} esperado=%h",
                         a, b, cin, cout_cla, sum_cla, expected);
            end else begin
                $display("[OK] CLA correcto: a=%h b=%h cin=%b -> sum=%h cout=%b",
                         a, b, cin, sum_cla, cout_cla);
            end
        end
    endtask
endmodule
