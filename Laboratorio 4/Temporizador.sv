module Temporizador #( 
    parameter bit Simulacion = 0
    )(
    input  logic        clk, reset,

    input  logic        TIMER_ctrl_we,
    input  logic [31:0] TIMER_ctrl_wdata,

    output logic [31:0] TIMER_done_rdata
);

    logic [31:0] contador;
    logic [31:0] limite;
    logic        activo;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            contador          <= 0;
            limite            <= 0;
            activo            <= 0;
            TIMER_done_rdata  <= 0;
        end

        else begin
            // Se inicia el timer
            if (TIMER_ctrl_we) begin
                limite           <= TIMER_ctrl_wdata;
                contador         <= 0;
                activo           <= 1;
                TIMER_done_rdata <= 0;
            end

            // Cuenta
            else if (activo) begin
                contador <= contador + 1;

                if (contador >= limite) begin
                    TIMER_done_rdata <= 1; // listo!
                    activo <= 0;
                end
            end
        end
    end
endmodule

