// Solucion del ejercicio 3.1
`timescale 1ns / 1ps
// switch_led_groups.sv
// Top sencillo: 16 switches -> 16 LEDs, 4 botones apagan cada grupo de 4 LEDs.
// Grupos: [3:0], [7:4], [11:8], [15:12]

module switch_led_groups (
    input  logic [3:0]  btn,   // 4 botones de la FPGA
    input  logic [15:0] sw,    // Todos los switches de la FPGA
    output logic [15:0] led    // Todos los leds de la FPGA
);

    // grupos y logica
    // assign: asignación continua (combinacional)
    // led[3:0] grupo de 4 led
    // btn[] (boton asignado)
    // ?: operador ternario (condicional), osea, "condición ? valor_si_verdadero : valor_si_falso"
    // Si la condición es verdadera (1), devuelve valor_si_verdadero.
    // Si es falsa (0), devuelve valor_si_falso.
    // 4'h0 : 4 es el número de bits, 'h es la base hexadecimal y 0 es para que todo sea 0000

    // Eso se hace para cada grupo hecho
    assign led[3:0]   = btn[0] ? 4'h0 : sw[3:0];
    
    assign led[7:4]   = btn[1] ? 4'h0 : sw[7:4];
    
    assign led[11:8]  = btn[2] ? 4'h0 : sw[11:8];
    
    assign led[15:12] = btn[3] ? 4'h0 : sw[15:12];

endmodule
