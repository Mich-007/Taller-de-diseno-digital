module register_file #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 5,   // 2^5 = 32 registros
    parameter NUM_REGS   = 32
)(
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  RegWrite,        // habilita escritura
    input  logic [ADDR_WIDTH-1:0] rs1, rs2, rd,    // direcciones de registros
    input  logic [DATA_WIDTH-1:0] write_data,      // dato a escribir
    output logic [DATA_WIDTH-1:0] read_data1,      // salida del registro rs1
    output logic [DATA_WIDTH-1:0] read_data2       // salida del registro rs2
);

// Banco de 32 registros de 64 bits
    logic [DATA_WIDTH-1:0] regfile [0:NUM_REGS-1];

// Lectura combinacional (rs1, rs2)
    assign read_data1 = (rs1 == 0) ? '0 : regfile[rs1];
    assign read_data2 = (rs2 == 0) ? '0 : regfile[rs2];

// Escritura secuencial
    always_ff @(posedge clk) begin
        if (reset) begin
            integer i;
            for (i = 0; i < NUM_REGS; i++) begin
                regfile[i] <= '0;
            end
        end else if (RegWrite && (rd != 0)) begin
            regfile[rd] <= write_data;
        end
    end
endmodule
