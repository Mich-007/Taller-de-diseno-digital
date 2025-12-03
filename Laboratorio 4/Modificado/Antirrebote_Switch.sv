`timescale 1ns / 1ps

module Antirrebote_Switch#(
    parameter bit Simulacion = 0,
    parameter DEBOUNCE_MS_HW = 10,
    parameter int CLK_HZ       = 10_000_000,
    parameter int DEBOUNCE_MS_SIM  = 0         
)(
    input logic clk, reset,
    input logic  [15:0] SW,
    output logic        sw0_db,
    output logic        sw_db_d0,
    output logic        sw1_db,
    output logic        sw_db_d1,
    output logic        sw2_db,
    output logic        sw_db_d2,
    output logic        sw3_db,
    output logic        sw_db_d3
    );
          
    localparam int DEBOUNCE_MS = Simulacion ? DEBOUNCE_MS_SIM : DEBOUNCE_MS_HW;
    localparam int DB_TICKS = Simulacion ? 2 : (CLK_HZ/1000)*DEBOUNCE_MS_HW;   // 2 ciclos en sim
    localparam int W = (DB_TICKS > 1) ? $clog2(DB_TICKS) : 1;
 
    logic sw0_meta, sw0_sync;
    logic sw1_meta, sw1_sync;
    logic sw2_meta, sw2_sync;
    logic sw3_meta, sw3_sync;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sw0_meta <= 1'b0;
            sw0_sync <= 1'b0;
            sw1_meta <= 1'b0;
            sw1_sync <= 1'b0;
            sw2_meta <= 1'b0;
            sw2_sync <= 1'b0;
            sw3_meta <= 1'b0;
            sw3_sync <= 1'b0;
        end else begin
            sw0_meta <= SW[0];
            sw0_sync <= sw0_meta;
            sw1_meta <= SW[1];
            sw1_sync <= sw1_meta;
            sw2_meta <= SW[2];
            sw2_sync <= sw2_meta;
            sw3_meta <= SW[3];
            sw3_sync <= sw3_meta;
        end
    end
  
// -------------------------------------------------------------------
//Antirrebote para el SW[0]
// -------------------------------------------------------------------  
    logic [W-1:0] cnt;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt   <= '0;
            sw0_db <= 1'b0;
        end else begin
            if (sw0_sync != sw0_db) begin
        // el usuario cambi  el switch: espera que se mantenga estable
                if (cnt == DB_TICKS-1) begin
                    sw0_db <= sw0_sync;
                    cnt   <= '0;
                end else begin
                    cnt <= cnt + 1'b1;
                end
        end else begin
            cnt <= '0; // estable: reinicia contador
            end
        end
    end
  
// -------------------------------------------------------------------
//Antirrebote para el SW[1]
// -------------------------------------------------------------------
    logic [W-1:0] cnt1;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt1   <= '0;
            sw1_db <= 1'b0;
        end else begin
            if (sw1_sync != sw1_db) begin
        // el usuario cambi  el switch: espera que se mantenga estable
                if (cnt1 == DB_TICKS-1) begin
                sw1_db <= sw1_sync;
                cnt1   <= '0;
            end else begin
                cnt1 <= cnt1 + 1'b1;
            end
        end else begin
            cnt1 <= '0; // estable: reinicia contador
            end
        end
    end

// -------------------------------------------------------------------
//Antirrebote para el SW[2]
// -------------------------------------------------------------------
    logic [W-1:0] cnt2;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt2   <= '0;
            sw2_db <= 1'b0;
        end else begin
            if (sw2_sync != sw2_db) begin
        // el usuario cambi  el switch: espera que se mantenga estable
                if (cnt2 == DB_TICKS-1) begin
                sw2_db <= sw2_sync;
                cnt2   <= '0;
            end else begin
                cnt2 <= cnt2 + 1'b1;
            end
        end else begin
            cnt2 <= '0; // estable: reinicia contador
            end
        end
    end

// -------------------------------------------------------------------
//Antirrebote para el SW[3]
// -------------------------------------------------------------------
    logic [W-1:0] cnt3;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt3   <= '0;
            sw3_db <= 1'b0;
        end else begin
            if (sw3_sync != sw3_db) begin
        // el usuario cambi  el switch: espera que se mantenga estable
                if (cnt3 == DB_TICKS-1) begin
                sw3_db <= sw3_sync;
                cnt3   <= '0;
            end else begin
                cnt3 <= cnt3 + 1'b1;
            end
        end else begin
            cnt3 <= '0; // estable: reinicia contador
            end
        end
    end
           
  // 3) Detector de flanco 0?1 y pulso de 1 ciclo
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin 
            sw_db_d0 <= 1'b0;
            sw_db_d1 <= 1'b0;
            sw_db_d2 <= 1'b0;
            sw_db_d3 <= 1'b0;
        end
        else  begin    
            sw_db_d0 <= sw0_db;
            sw_db_d1 <= sw1_db;
            sw_db_d2 <= sw2_db;
            sw_db_d3 <= sw3_db;
        end
    end

endmodule
