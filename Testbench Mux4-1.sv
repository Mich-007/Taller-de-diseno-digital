`timescale 1ns/1ps // Escala de tiempo 

//======================================================
            // MUX 4 a 1  ZONA DE PRUEBAS 
//======================================================

module m4_1_tb;// Nombre del modulo

    parameter N = 16; // Escojo la parametrizacion, en nuestro caso seria, de 4,8 y 16 bits

    logic [N-1:0] d0, d1, d2, d3; // Vuelvo de definir las entradas, salidas, seleccionador, 
    logic [1:0]   se;
    logic [N-1:0] y;
    logic [N-1:0] expected; // defnmos una variable de referencia en el testbench para verificar que la salida sea correcta. 

    // Instancia del DUT o Dispostivo bajo prueba, en este caso es el modulo que le queremos hacer pruebas 
    m4_1 #(.N(N)) dut (
        .d0(d0), .d1(d1), .d2(d2), .d3(d3),
        .se(se), .y(y)
    );

    integer i;  // contador de pruebas

    initial begin // Inicia la prueba 
        $display("======================================================");
        $display("      TESTBENCH MUX 4 a 1 (N=%0d bits)   ", N); 
        $display("======================================================");

        $display("Prueba | se |    d0   |    d1   |    d2   |    d3   |  esperado |  obtenido | Resultado");
        $display("----------------------------------------------------------------------------------------");

        // GENERADOR DE 50 PRUEBAS 
        for (i = 0; i < 50; i = i + 1) begin // i= 0, para i menor de 50 sigue generando hasta llegar a 49
            // Genera entradas aleatorias
            d0 = $urandom;
            d1 = $urandom;
            d2 = $urandom;
            d3 = $urandom;
            se = $urandom % 4;// Lmtamos el selecconador para que solo escoja valores entre 0 y 3, lo necesario 

            // Calcular salida esperada
            case (se)
                2'b00: expected = d0; // Compara que lo que escoja mi selecconador sea lo esperado con la salida 
                2'b01: expected = d1; // Tencamente es el resultado verdadero (lo que debería salir), 
                2'b10: expected = d2; // calculado por el testbench según la lógica del MUX.
                2'b11: expected = d3;
            endcase

            #1; //  retardo de 1 ns  

            // Mostrar resultados
            if (y !== expected) begin  // si mi salida es dferente al expeccted, el programa dara Error , en caso contrario un OK 
                $display("%2d     | %2b  | %h | %h | %h | %h |    %h    |    %h    |   ERROR",
                          i, se, d0, d1, d2, d3, expected, y);
            end else begin // salida en mi TCL console si mi saldia es igual al expected. 
                $display("%2d     | %2b  | %h | %h | %h | %h |    %h    |    %h    |   OK",
                          i, se, d0, d1, d2, d3, expected, y);
            end
        end

        $display("----------------------------------------------------------------------------------------");
        $display("                   FIN DE LAS 50 PRUEBAS");
        $display("========================================================================================");
        $finish;
    end

endmodule
