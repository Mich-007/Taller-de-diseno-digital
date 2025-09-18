`timescale 1ns/1ps

package fsm_pkg;
typedef enum logic [3:0] {
  S_Espera, S_EsperaS, S_EsperaBTN, S_LFSRA, S_LFSRB, S_ALU, S_Display
} estado_t;
endpackage

module Control #(
  parameter bit Simulacion = 0,    
  parameter int CLK_HZ       = 10_000_000, 
  parameter int DEBOUNCE_MS  = 10          
)(
    input logic         clk, reset,
    input logic         LFSRvalido,
    input logic         ALUvalido, valor_leer_listo,
    input logic         sw0_db, sw_db_d0, sw1_db, sw_db_d1,
    input logic  [15:0] SW,ALUResult, leer_data,
    input logic  [3:0]  BTN,
    input logic  [6:0]  LFSRdato,
    input logic  [5:0]  REGContador,
    input logic  [4:0]  REGposicion,
    output logic [15:0] nuevo_dato,DisplayValor, REGvalor, LED,
    output logic [6:0]  ALUA,ALUB, s_valor,
    output logic [4:0]  leer_index,     // índice actual a leer del Registro
    output logic [1:0]  op_lat,
    output logic        LFSRiniciar,s_cargar,
    output logic        ALUiniciar,
    output logic        PulsoMitad, PulsoFin, Displayiniciar, DisplayDone,      
    output logic        REGiniciar, REGdisplay,  leer_ahora     


);
    import fsm_pkg::*;
    typedef enum logic [2:0] {R_Espera, R_SetIndex,R_EsperaDato, R_Pausa, R_Index} r_estado;
    
// -------------------------------------------------------------------
//Configuración de estados
// -------------------------------------------------------------------
    r_estado estadoregistro;
    r_estado r_estado_q;
    estado_t estado_actual = S_Espera, estado_siguiente;
    estado_t origen_display;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin 
            estado_actual <= S_Espera;
        end else begin     
            estado_actual <= estado_siguiente;
            end
        end
    
    always_ff @(posedge clk or posedge reset)
        if (reset) r_estado_q <= R_Espera;
        else       r_estado_q <= estadoregistro;
    
     always_ff @(posedge clk or posedge reset) begin
        if (reset) origen_display <= S_Espera;
        else if ((estado_siguiente == S_Display) && (estado_actual != S_Display))
            origen_display <= estado_actual;  // guarda S_LFSRA / S_LFSRB / S_ALU
        end    

 // -------------------------------------------------------------------  
//Contador de Display que se encarga de que cada valor se vea por 2 segundos
 // -------------------------------------------------------------------
    localparam int MAX_COUNT = Simulacion ? 20 : 20_000_000;
    localparam int unsigned HALF = MAX_COUNT/2;    
    logic VentanaActiva;
    logic[$clog2(MAX_COUNT)-1:0] DisplayContador;  
                
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            VentanaActiva <= 1'b0;
            DisplayContador <= '0;
            PulsoMitad <= 1'b0;
            PulsoFin <= 1'b0;
        end else begin
            PulsoMitad <= 1'b0;
            PulsoFin<= 1'b0;            
            if(Displayiniciar) begin
                VentanaActiva <= 1'b1;              
                DisplayContador <= MAX_COUNT -1;
            end else if (VentanaActiva) begin
            if(DisplayContador == 0) begin
                PulsoFin <= 1'b1;
                VentanaActiva <= 1'b0;
            end else begin 
            if (DisplayContador == HALF)
                PulsoMitad <= 1'b1;
                DisplayContador <= DisplayContador - 1'b1; 
            end
         end
      end     
   end

 // -------------------------------------------------------------------
    // Modo Registro   
 // -------------------------------------------------------------------
    logic REGLeer, start_pulse;
    assign REGLeer = sw1_db & ~sw_db_d1;
    wire modo_registro = sw1_db;
    logic [4:0] base_index;   // índice del más antiguo
    logic [5:0] k;          // cuántos llevamos mostrados
    logic [7:0] data_registro;
    wire displayFSM = (estado_actual != S_Display)&& (estado_siguiente == S_Display);
    wire displayregistro = (r_estado_q != R_Pausa) && (estadoregistro == R_Pausa);



    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            estadoregistro    <= R_Espera;
            base_index  <= '0;
            k         <= '0;
            leer_index    <= '0;
            leer_ahora <= 1'b0;
        end else if (modo_registro) begin
            leer_ahora <=1'b0;
            case (estadoregistro)
                R_Espera: if(REGLeer) begin
                    base_index <= REGposicion - REGContador[4:0];
                    k        <= 6'd0;
                    estadoregistro   <= R_SetIndex;
                end
                R_SetIndex: begin
                    leer_index <= base_index + k[4:0]; 
                    estadoregistro <= R_Index;
                end
                R_Index: begin
                    leer_ahora <=1'b1;         
                    estadoregistro <= R_EsperaDato;
                    end
                
                R_EsperaDato: if(valor_leer_listo)begin 
                    data_registro  <= leer_data;
                    estadoregistro <= R_Pausa;
                end
        
                R_Pausa: begin
                    if (PulsoFin) begin
                        if (k + 6'd1 >= REGContador) begin
                            estadoregistro <= R_Espera;
                        end else begin
                            k      <= k + 6'd1;
                            estadoregistro <= R_SetIndex;
                        end
                    end
                end
            endcase
        end else begin
            estadoregistro <= R_Espera;
            leer_ahora <= 1'b0;
        end
    end

 // -------------------------------------------------------------------
//Generar semilla para la LFSR
 // -------------------------------------------------------------------
    logic s_listo;
    logic [6:0] s_contador;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            s_contador  <= 7'd1;
            s_listo    <= 1'b0;
            s_cargar <= 1'b0;
            s_valor   <= 7'd1;
        end else begin
            s_cargar <= 1'b0;                
        if (!s_listo)  s_contador <=  s_contador + 1'b1;
            if (!s_listo && start_pulse) begin
                s_valor  <= (s_contador==7'd0) ? 7'd1 :  s_contador;
                s_cargar <= 1'b1;
                s_listo  <= 1'b1;
            end
        end
    end

 // -------------------------------------------------------------------    
//Iniciar Módulos       
 // -------------------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        LFSRiniciar <= 1'b0;
        ALUiniciar <= 1'b0;
    end else begin
        LFSRiniciar <= (estado_actual != S_LFSRA && estado_siguiente == S_LFSRA) ||
                     (estado_actual != S_LFSRB && estado_siguiente == S_LFSRB);
        ALUiniciar <= (estado_actual != S_ALU) && (estado_siguiente == S_ALU);        
        end
    end
    
// -------------------------------------------------------------------    
//Activación y guardado de datos en registro  
// -------------------------------------------------------------------
    logic reg_wr;
    logic [7:0] wr_data; //valor que se guarda en el registro        
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            REGiniciar <= 1'b0;
            nuevo_dato <= 8'h00;
        end else begin
            REGiniciar <= reg_wr;
            nuevo_dato <= wr_data;
        end
    end
        
// -------------------------------------------------------------------
// Antirebote BTN
// -------------------------------------------------------------------
    logic [3:0] btn_pressed, btn_press, btn_release;

    for (genvar i=0; i<4; i++) begin : G_BTN
        ButtonDebounce #(
            .CLK_HZ(CLK_HZ), .ACTIVE_HIGH(1), .Simulacion(Simulacion) // ajusta polaridad a tu placa
        ) db (
            .clk(clk), .reset(reset),
            .BTN(BTN[i]),
            .pressed(btn_pressed[i]),
            .press_pulse(btn_press[i]),
            .release_pulse(btn_release[i])
        );
    end
 
    wire select_window = (estado_actual == S_Display) && (origen_display == S_LFSRB);

    function automatic [1:0] decode_btn(input [3:0] b);
        unique case (1'b1)
            b[0]: decode_btn = 2'b00; // AND
            b[1]: decode_btn = 2'b01; // OR
            b[2]: decode_btn = 2'b10; // ADD
            b[3]: decode_btn = 2'b11; // SUB
            default: decode_btn = op_lat; 
        endcase
    endfunction

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            op_lat <= 2'b00;     
        end else begin
        if (select_window && (|btn_press))
            op_lat <= decode_btn(btn_press);
        else if (estado_actual == S_EsperaBTN && (|btn_pressed))
            op_lat <= decode_btn(btn_pressed);
        end
    end
    
 // -------------------------------------------------------------------
//Guardar los valores de A y B en el registro
 // -------------------------------------------------------------------
    assign start_pulse = sw0_db & ~sw_db_d0;
    always_comb begin
    estado_siguiente = estado_actual;
    reg_wr  = 1'b0;
    wr_data = 8'h00;
    unique case (estado_actual)      
        S_Espera: if(start_pulse)begin
            estado_siguiente = S_EsperaS;
        end         
        S_EsperaS : begin
            if (s_listo) begin
                estado_siguiente = S_LFSRA;
            end
        end
        S_LFSRA: if (LFSRvalido) begin
            reg_wr  = 1'b1;
            wr_data = LFSRdato;    
            estado_siguiente = S_Display; 
        end
        S_LFSRB: if (LFSRvalido) begin
            reg_wr  = 1'b1;
            wr_data = LFSRdato;
            estado_siguiente = S_Display;
        end          
       S_EsperaBTN: begin
            if (|btn_pressed) estado_siguiente = S_ALU;
        end
        S_ALU  : if (ALUvalido)  begin
            reg_wr  = 1'b1;
            wr_data = ALUResult;
            estado_siguiente = S_Display;   
        end 
                         
        S_Display: begin    
            unique case (origen_display) 
                S_LFSRA: begin             
                    if(PulsoFin) begin
                        estado_siguiente = S_LFSRB;  
                    end           
                end              
                S_LFSRB: begin
                    if (PulsoFin) 
                        estado_siguiente = S_EsperaBTN;
                end
                S_ALU: begin             
                    if(PulsoFin) begin   
                        estado_siguiente = S_Espera;   
                    end           
                end
                default: begin
                if(PulsoFin)
                    estado_siguiente = S_Espera;
                end
            endcase
        end
        default: ;
    endcase          
    end
    
 // -------------------------------------------------------------------
//Darle los valores generados a A y B correspondientemente
 // -------------------------------------------------------------------
    always_ff @(posedge clk ) begin
        if (estado_actual == S_LFSRA && LFSRvalido) begin 
            ALUA <= {9'b0, LFSRdato};
            end
        if (estado_actual == S_LFSRB && LFSRvalido) begin
            ALUB <= {9'b0, LFSRdato};
            end
        end
 // -------------------------------------------------------------------    
//Iniciar el Display para que muestre los valores correspondientes
 // -------------------------------------------------------------------

    always_ff @(posedge clk or posedge reset) begin 
        if (reset) begin Displayiniciar <= 1'b0; 
            DisplayValor <= 8'h00; 
        end else begin // Pulso único hacia Display 
            Displayiniciar <= 1'b0; // Valor estable en el mismo ciclo del pulso 
        if (displayregistro) begin 
            Displayiniciar <= 1'b1; 
            DisplayValor <= data_registro; 
        end else if(displayFSM) begin 
            Displayiniciar <= 1'b1; 
            unique case (estado_actual) 
                S_LFSRA: DisplayValor <= {9'b0, LFSRdato}; 
                S_LFSRB: DisplayValor <= {9'b0, LFSRdato}; 
                S_ALU :  DisplayValor <= ALUResult; 
                default: DisplayValor <= 8'h00; 
            endcase 
            end 
        end 
    end
  
// -------------------------------------------------------------------
//Control de los LEDS   
// -------------------------------------------------------------------
   
    function automatic logic [15:0] onehot_idx(input int idx);
        logic [15:0] v = 16'h0000;
        v[idx] = 1'b1;
        return v;
    endfunction
    
    function automatic logic [15:0] led_from_op(input logic [1:0] op);
        unique case (op)
            2'b00: return onehot_idx(2); // AND
            2'b01: return onehot_idx(3); // OR
            2'b10: return onehot_idx(4); // SUMA
            default: return onehot_idx(5); // RESTA
        endcase
    endfunction
    
    // Para modo registro: 0?A, 1?B, 2?R, 3?A, 4?B, 5?R, ...
    function automatic logic [15:0] led_for_registro(input logic [5:0] k_val);
        case (k_val % 3)
            2'd0:  return onehot_idx(0); // A
            2'd1:  return onehot_idx(1); // B
            default:return onehot_idx(2); // R
      endcase
    endfunction
    
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin 
            LED <= 16'h0000; // todos apagados
        end else begin
            if (Displayiniciar) begin
          // Cuando inicia una nueva "pantalla":
                if (modo_registro) begin
            // MODO REGISTRO: LED rota 0,1,2 según k
                    LED <= led_for_registro(k);
            end else begin
            // FSM normal: A,B y ALU según operación
                unique case (origen_display)
                    S_LFSRA: LED <= onehot_idx(0);        // LED0 = A
                    S_LFSRB: LED <= onehot_idx(1);        // LED1 = B
                    S_ALU  : LED <= led_from_op(op_lat);  // LED por operación
                    default: LED <= 16'h0000;
                endcase
            end
            end else if (PulsoFin) begin
                 // Al terminar la ventana, apaga
                LED <= 16'h0000;
            end
        end
    end
             
endmodule
