`timescale 1ns / 1ps
module Top#(
    parameter bit Simulacion = 0, 
    parameter int CLK_HZ       = 10_000_000, // ej. Nexys4: 100 MHz
    parameter int DEBOUNCE_MS  = 10           // ~10 ms suele ir bien
)(
    input logic         clk_100, reset,
    input logic [15:0]  SW,
    input logic [3:0]   BTN,
    output logic [7:0]  AN,
    output logic [6:0]  SEG,
    output logic [15:0] LED
);
    logic [1:0]op_lat; 
    logic [4:0] leer_index, REGposicion;     // índice actual a leer del Registro
    logic [5:0] REGContador;
    logic [6:0] ALUA, ALUB;
    logic [6:0] LFSRdato, s_valor;   
    logic [15:0] leer_data, nuevo_dato;    // dato leído del Registro
    logic [15:0] ALUResult;
    logic [15:0] DisplayValor; 
    logic LFSRiniciar, LFSRvalido, s_cargar;
    logic REGiniciar, valor_leer_listo, leer_ahora;
    logic Displayiniciar, PulsoMitad, PulsoFin;  
    logic ALUiniciar, ALUvalido;
    logic clk_10Mhz, locked_10M;
    logic sw0_db, sw_db_d0, sw1_db, sw_db_d1;
     

// -------------------------------------------------------------------
//Reloj de 10 MHz
// -------------------------------------------------------------------
    design_1 u_bd (.clk_0(clk_100),
    .clk_10Mhz(clk_10Mhz),
    .rst_0(reset), .locked_0(locked_10M));   
     
// -------------------------------------------------------------------
//Control
// ------------------------------------------------------------------- 
    Control #(.Simulacion(Simulacion))
    uC(.clk(clk_10Mhz), .reset(reset),
    .LFSRiniciar(LFSRiniciar), .LFSRvalido(LFSRvalido), .LFSRdato(LFSRdato), .s_valor(s_valor), .s_cargar(s_cargar), 
    .nuevo_dato(nuevo_dato), .REGiniciar(REGiniciar), .REGContador(REGContador),.REGposicion(REGposicion), .leer_index(leer_index), .leer_data(leer_data),
    .valor_leer_listo(valor_leer_listo), .leer_ahora(leer_ahora),
    .ALUA(ALUA), .ALUB(ALUB), .ALUiniciar(ALUiniciar), .ALUResult(ALUResult), .ALUvalido(ALUvalido),.op_lat(op_lat),
    .DisplayValor(DisplayValor), .Displayiniciar(Displayiniciar), .PulsoMitad(PulsoMitad), .PulsoFin(PulsoFin),
    .LED(LED), .SW(SW),.BTN(BTN), .sw0_db(sw0_db), .sw_db_d0(sw_db_d0), .sw1_db(sw1_db), .sw_db_d1(sw_db_d1));

// -------------------------------------------------------------------
//LFSR
// -------------------------------------------------------------------
  
    LFSR uL (.clk(clk_10Mhz), .reset(reset), .LFSRvalido(LFSRvalido),
    .LFSRiniciar(LFSRiniciar), .LFSRdato(LFSRdato), .s_valor(s_valor), .s_cargar(s_cargar));
    
// -------------------------------------------------------------------
//Registro
// -------------------------------------------------------------------  
    Registro uR (.clk(clk_10Mhz), .reset(reset), 
    .nuevo_dato(nuevo_dato), .REGiniciar(REGiniciar), .REGContador(REGContador), .REGposicion(REGposicion), .leer_index(leer_index), .leer_data(leer_data),
    .valor_leer_listo(valor_leer_listo), .leer_ahora(leer_ahora));
    
// -------------------------------------------------------------------
//ALU
// -------------------------------------------------------------------  
    ALU uA (.ALUA(ALUA), .ALUB(ALUB), .ALUiniciar(ALUiniciar),.ALUvalido(ALUvalido), .ALUResult(ALUResult),.BTN(BTN), .op_lat(op_lat));
    
// -------------------------------------------------------------------
//Display
// -------------------------------------------------------------------  
    Display uD(.clk(clk_10Mhz), .reset(reset), 
    .DisplayValor(DisplayValor), 
    .SEG(SEG), .AN(AN), .Displayiniciar(Displayiniciar), .PulsoMitad(PulsoMitad), .PulsoFin(PulsoFin));
    
// -------------------------------------------------------------------
//Antirrebotes
// -------------------------------------------------------------------    
    Antirrebote_Switch#(.Simulacion(Simulacion))
     uS(.clk(clk_10Mhz), .reset(reset), .SW(SW),
    .sw0_db(sw0_db), .sw_db_d0(sw_db_d0),.sw1_db(sw1_db), .sw_db_d1(sw_db_d1));
    
    ButtonDebounce #(.Simulacion(Simulacion)) uB (.clk(clk_10Mhz), .reset(reset));
    
endmodule

