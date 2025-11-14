`timescale 1ns / 1ps

module Antirrebote_Switch#(
    parameter bit Simulacion = 0,
    parameter DEBOUNCE_MS_HW = 10,
    parameter int CLK_HZ       = 16_000_000,
    parameter int DEBOUNCE_MS_SIM  = 0         
)(
    input logic clk, reset,
    input logic [15:0] SW,
    output logic sw0_db,
    output logic sw_db_d0,
    output logic sw1_db,
    output logic sw_db_d1
    );

    localparam int DEBOUNCE_MS = Simulacion ? DEBOUNCE_MS_SIM : DEBOUNCE_MS_HW;
    localparam int DB_TICKS    = Simulacion ? 2 : (CLK_HZ/1000)*DEBOUNCE_MS;
    localparam int W = (DB_TICKS > 1) ? $clog2(DB_TICKS) : 1;
 
    logic sw0_meta, sw0_sync;
    logic sw1_meta, sw1_sync;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sw0_meta <= 1'b0;
            sw0_sync <= 1'b0;
            sw1_meta <= 1'b0;
            sw1_sync <= 1'b0;
        end else begin
            sw0_meta <= SW[0];
            sw0_sync <= sw0_meta;
            sw1_meta <= SW[1];
            sw1_sync <= sw1_meta;
        end
    end
  
// ___________________________________________________________________
//Antirrebote para el SW[0]
// 
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
  
// ___________________________________________________________________
//Antirrebote para el SW[1]
// 
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
    
  // 3) Detector de flanco 0?1 y pulso de 1 ciclo
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin 
            sw_db_d0 <= 1'b0;
            sw_db_d1 <= 1'b0;
        end
        else  begin    
            sw_db_d0 <= sw0_db;
            sw_db_d1 <= sw1_db;
        end
    end

endmodule
