module ButtonDebounce #(
    parameter int CLK_HZ=16_000_000,
    parameter bit ACTIVE_HIGH=1,
    parameter bit  Simulacion = 0,
    parameter DEBOUNCE_MS_HW = 7,
    parameter int DEBOUNCE_MS_SIM  = 0           // ~10 ms suele ir bien
)(
    input  logic clk, reset,
    input  logic BTN,          // 1 bit
    output logic pressed,
    output logic press_pulse,
    output logic release_pulse
);

    localparam int DEBOUNCE_MS = Simulacion ? DEBOUNCE_MS_SIM : DEBOUNCE_MS_HW;
    localparam int DB_TICKS    = Simulacion ? 2 : (CLK_HZ/1000) * DEBOUNCE_MS;
    localparam int W = (DB_TICKS > 1) ? $clog2(DB_TICKS) : 1;
    
    wire b = ACTIVE_HIGH ? BTN : ~BTN;
    logic [W-1:0] cnt;
    logic m,s;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin m<=0; s<=0; end
        else begin m<=b; s<=m; end
    end
  
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin pressed<=0; cnt<='0; end
        else if (s!=pressed) begin
            if (cnt==DB_TICKS-1) begin pressed<=s; cnt<='0; end
            else cnt<=cnt+1'b1;
        end else 
            cnt<='0;
    end
  
    logic d;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) d<=0; else d<=pressed;
    end
    
    assign press_pulse   =  pressed & ~d;
    assign release_pulse = ~pressed &  d;
endmodule
