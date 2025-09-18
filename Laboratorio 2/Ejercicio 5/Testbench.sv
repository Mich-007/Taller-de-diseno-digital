`timescale 1ns/1ps
 
module tb_top; 
    logic clk, reset; 
    logic [15:0] SW; 
    logic [3:0] BTN; 
    wire [15:0] LED; 
    wire [7:0] AN; 
    wire [6:0] SEG; 
    int iter_cnt = 0; 
    
    Top #(.Simulacion(1)) uut(
        .clk_100(clk), .reset(reset), .SW(SW), .BTN(BTN), .LED(LED), 
        .AN(AN), .SEG(SEG) ); // Reloj 100 MHz 

    import fsm_pkg::*;
 
    function automatic [3:0] op2btn(input [1:0] op);
      case (op)
        2'b00: op2btn = 4'b0001; // AND
        2'b01: op2btn = 4'b0010; // OR
        2'b10: op2btn = 4'b0100; // ADD
        default: op2btn = 4'b1000; // SUB
      endcase
    endfunction

// Pulsa dentro de la ventana (S_Display, origen S_LFSRB) y mantén hasta S_ALU
    task automatic press_op_in_window_hold_to_alu(input [1:0] op, input int db_cycles=2);
  // Espera la ventana de clic
        wait (uut.uC.estado_actual == fsm_pkg::S_Display &&
        uut.uC.origen_display == fsm_pkg::S_LFSRB);
        @(posedge uut.clk_10Mhz);

  // Afirmar el botón elegido (duración ? debounce en sim)
        BTN = op2btn(op);
        repeat (db_cycles) @(posedge uut.clk_10Mhz);

  // Mantener apretado hasta entrar a S_ALU
        wait (uut.uC.estado_actual == fsm_pkg::S_ALU);
  // Opcional: sostener 1-2 ciclos más y soltar
        repeat (1) @(posedge uut.clk_10Mhz);
        BTN = 4'b0000;
    endtask
        
   initial begin 
       clk = 0; 
       forever #5 clk = ~clk; 
   end //add_wave -radix hex /tb_top/uut/uC/DisplayValor 
   // Imprimir SOLO cuando DisplayValor == ALUResult, sincronizado al reloj 
    // S_Espera, S_Display       

    task automatic press_sw0_cycles(input int hi=2, input int lo=2);
        SW[0]=1; repeat(hi) @(posedge uut.clk_10Mhz);
        SW[0]=0; repeat(lo) @(posedge uut.clk_10Mhz);
    endtask

    task automatic press_sw1_cycles(input int len=2, input bit hold_high=1);
        SW[1]=1; repeat(len) @(posedge uut.clk_10Mhz);
        if (!hold_high) begin SW[1]=0; repeat(2) @(posedge uut.clk_10Mhz); end
    endtask

    initial begin
        SW='0;
        reset=1; 
        repeat(11) @(posedge clk); 
        reset=0;     // reset 100 MHz
        
        wait (uut.locked_10M === 1'b1);                  // si tu wizard simula
        repeat (3) @(posedge uut.clk_10Mhz);             // ventana muerta corta

        wait (uut.uC.estado_actual == fsm_pkg::S_Espera);
        @(posedge uut.clk_10Mhz);

    for (int i=0;i<11;i++) begin
        press_sw0_cycles(2,2);                         // alto y bajo ? debounce sim
        press_op_in_window_hold_to_alu(i[1:0], /*db_cycles=*/2);
        wait (uut.uC.estado_actual == fsm_pkg::S_Espera);
        @(posedge uut.clk_10Mhz);
    end

    press_sw1_cycles(2, 1'b1);                       // modo registro
    repeat (20_00) @(posedge uut.clk_10Mhz);
    $finish;
end

logic disp_q;
always_ff @(posedge uut.clk_10Mhz or posedge reset) begin
  if (reset) disp_q <= 1'b0;
  else       disp_q <= uut.uC.Displayiniciar;
end

// Un print por evento:
always @(posedge uut.clk_10Mhz) if (uut.uC.Displayiniciar && !disp_q) begin
  unique case (uut.uC.origen_display)
    fsm_pkg::S_LFSRA: $display("[A] t=%0t A=%02h DV=%04h", $time, uut.ALUA, uut.DisplayValor);
    fsm_pkg::S_LFSRB: $display("[B] t=%0t B=%02h DV=%04h", $time, uut.ALUB, uut.DisplayValor);
    fsm_pkg::S_ALU  : begin
      iter_cnt++;
      $display("[ALU] t=%0t A=%02h B=%02h op=%02b R=%04h DV=%04h (ciclo %0d)",
               $time, uut.ALUA, uut.ALUB, uut.uC.op_lat, uut.ALUResult,
               uut.DisplayValor, iter_cnt);
    end
  endcase
  end
endmodule