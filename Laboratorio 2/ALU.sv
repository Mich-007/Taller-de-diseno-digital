module ALU #(
    parameter int N = 7
)(
    input  logic [N-1:0] ALUA, ALUB,
    input  logic [3:0]   BTN,
    input  logic [1:0]   op_lat,
    input  logic         ALUiniciar,
    output logic [15:0]  ALUResult,
    output logic         ALUvalido
);

    always_comb begin
        ALUResult = 16'h0000;
        unique case (op_lat)
            2'b00: ALUResult = {9'b0, (ALUA & ALUB)}; // AND
            2'b01: ALUResult = {9'b0, (ALUA | ALUB)}; // OR
            2'b10: ALUResult = ALUA + ALUB;           // ADD
            2'b11: ALUResult = ALUA - ALUB;           // SUB
            default: ALUResult = 16'h0000;
        endcase
    // Para salir de S_ALU el mismo ciclo:
        ALUvalido = 1'b1;
    end
    
endmodule

