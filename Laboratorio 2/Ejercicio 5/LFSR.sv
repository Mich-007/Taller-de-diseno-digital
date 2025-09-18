module LFSR (
    input  logic clk, reset,
    input  logic LFSRiniciar,
    input  logic s_cargar,        // << nuevo
    input  logic [6:0] s_valor,    // << nuevo
    output logic [6:0] LFSRdato,
    output logic       LFSRvalido

);
    logic [6:0] s;
    logic next_bit;
    logic [6:0] next_s;
    assign next_bit = s[6] ^ s[5];
    assign next_s   = {s[5:0], next_bit};
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            s <= 7'b0000001; LFSRdato <= '0; LFSRvalido <= 1'b0;
        end else begin
            LFSRvalido <= 1'b0;
            if (s_cargar) begin
                s <= (s_valor==7'd0) ? 7'd1 : s_valor;  // evita 0
            end else if (LFSRiniciar) begin
                s         <= next_s;
                LFSRdato  <= next_s;
                LFSRvalido<= 1'b1;
            end
        end
    end
    
endmodule


