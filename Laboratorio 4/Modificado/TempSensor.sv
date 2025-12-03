module TempSensor #( 
    parameter bit Simulacion = 0
    )(
    input  logic        clk, reset,

    input  logic        TEMP_ctrl_we,
    input  logic [31:0] TEMP_ctrl_wdata,

    output logic [31:0] TEMP_data_rdata,
    output logic [31:0] TEMP_done_rdata,

    input  logic [15:0] XADC_data,
    input  logic        XADC_ready
);

    logic activo;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            activo          <= 0;
            TEMP_done_rdata <= 0;
            TEMP_data_rdata <= 0;
        end
        else begin
            // inicia lectura
            if (TEMP_ctrl_we) begin
                activo          <= 1;
                TEMP_done_rdata <= 0;
            end

            // cuando XADC da dato
            if (activo && XADC_ready) begin
                TEMP_data_rdata <= {16'b0, XADC_data};
                TEMP_done_rdata <= 1;
                activo <= 0;
            end
        end
    end
                
endmodule
