`timescale 1ns/1ps   // Esto define la escala de tiempo para la simulación
                    
// ========================================================================
// Testbench para el ejercicio 3.1
// Objetivo: verificar que los 16 switches controlan los LEDs
//           y que cada grupo de 4 LEDs se apaga si su botón está activo
// ========================================================================

module tb_switch_led_groups;

    // Declaración de señales de prueba 

    logic [3:0]  btn;  // 4 botones de control (entradas al DUT)
    wire  [15:0] led;  // 16 LEDs de salida (salida del DUT)
    logic [15:0] sw;   // 16 switches de entrada (entradas al DUT)

    // ====================================================================
    // Instanciamos el DUT
    // Este es el módulo real que queremos probar
    // Conectamos sus entradas/salidas a las señales del testbench
    // ====================================================================
    switch_led_groups dut (
        .sw(sw),
        .btn(btn),
        .led(led)
    );

    // ================================
    // Proceso inicial de simulación
    // Aquí definimos los casos de prueba
    // ================================
    initial begin
      
      $display("========== Inicio Testbench 3.1 =========="); // Mensaje para saber que arranca la simulación

        // Caso inicial: todo apagado
        sw = 16'h0000;      // Todos los switches en 0
        btn = 4'b0000;      // Ningún botón presionado
        #10;                // Esperamos 10 ns para observar el comportamiento

        // 
        // Caso 1: LEDs deben seguir switches si ningún botón está presionado
        // 
      sw = 16'hA5A5;  // Patrón alternante (ejemplo: 1010 0101 ... varios más)
        #10;      // Esperamos para que se propague
      
        if (led !== sw) // Verificamos que los LEDs sigan exactamente el valor de sw
            $error("Fail: leds deben igualar a sw cuando btn=0");
      
        // 
        // Caso 2: apagar grupo 1 (LEDs 7..4)
        // 
        btn = 4'b0010; #10;   // Presionamos solo el botón 1
      
        if (led[7:4] !== 4'h0)        $error("Fail: grupo1 no apaga");

      
        //
        // Caso 3: apagar grupo 0 (LEDs 3..0)
        //
        btn = 4'b0001; #10;   // Presionamos solo el botón 0
      
        if (led[3:0] !== 4'h0)        $error("Fail: grupo0 no apaga");
      
        if (led[15:4] !== sw[15:4])   $error("Fail: otros grupos no deben cambiar");

        // 
        // Caso 4: apagar múltiples grupos (0 y 2)
        // 
        btn = 4'b0101; #10;   // Presionamos botones 0 y 2 simultáneamente
      
        if (led[3:0] !== 4'h0)        $error("Fail: grupo0 no apaga");
      
        if (led[11:8] !== 4'h0)       $error("Fail: grupo2 no apaga");
      
        if (led[7:4] !== sw[7:4])     $error("Fail: grupo1 alterado indebidamente");
      
        if (led[15:12] !== sw[15:12]) $error("Fail: grupo3 alterado indebidamente");

        // ========================
        // Barrido simple (sweep)
        // Recorremos los 4 grupos y apagamos uno por uno
        // ========================
        btn = 4'b0000;               // Reiniciamos los botones
      
        repeat (4) begin : sweep     // Repetimos 4 veces, una por grupo
            integer g = $time/10;    // Variable que usa el tiempo de simulación para decidir el grupo
            sw = 16'hFFFF;           // Todos los switches encendidos
            btn = 4'b0000; #5;       // Ningún botón al inicio
            btn[g] = 1'b1; #5;       // Activamos el botón del grupo "g"
        end

      $display("========== Final Testbench =========="); // Mensaje de cierre
      
        #10 $finish;              // Terminamos la simulación
      
    end

endmodule
