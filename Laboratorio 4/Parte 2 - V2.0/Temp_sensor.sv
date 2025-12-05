`timescale 1ns / 1ps
module TempSensor #(
    parameter bit Simulacion = 0
)(
    input  logic        clk,
    input  logic        reset,

    // Desde el CPU
    input  logic        TEMP_ctrl_we,
    input  logic [31:0] TEMP_ctrl_wdata,

    output logic [31:0] TEMP_data_rdata,
    output logic        TEMP_done_rdata,

    // I2C físico (solo HW)
    output logic scl,
    inout  tri   sda,
    output logic i2c_start,
    output logic i2c_busy, 
    output logic i2c_done, 
    output logic i2c_err
);

    localparam logic [6:0] ADT_ADDR = 7'h4B;

    logic temp_start;
    assign temp_start = TEMP_ctrl_we && TEMP_ctrl_wdata[0];

    // ===== SIMULACIÓN =====
    logic        sim_activo;
    logic [15:0] sim_cnt;
    logic [15:0] temp_sim;

    // ===== I2C =====
    logic i2c_next;
    logic [7:0] i2c_data_wr;
    logic [7:0] i2c_data_rd;
    
    I2C_Master_Byte i2c (
        .clk       (clk),
        .reset     (reset),
        .start     (i2c_start),
        .addr      (ADT_ADDR),
        .rw        (1'b1),
        .data_wr   (i2c_data_wr),
        .next      (i2c_next),
        .data_rd   (i2c_data_rd),
        .busy      (i2c_busy),
        .done      (i2c_done),
        .ack_error (i2c_err),
        .scl       (scl),
        .sda       (sda)
    );

    typedef enum logic [2:0] {
        S_IDLE,
        S_WAIT_MSB,
        S_WAIT_LSB,
        S_DONE
    } fsm_t;

    fsm_t state;
    logic [7:0] msb, lsb;

    //----------------------------------------------------------
    // UN SOLO ALWAYS
    //----------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin

        if (reset) begin

            // outputs
            TEMP_data_rdata <= 32'd0;
            TEMP_done_rdata <= 1'b0;

            // sim
            sim_activo <= 1'b0;
            sim_cnt    <= 16'd0;
            temp_sim   <= 16'd250;

            // i2c
            state     <= S_IDLE;
            msb       <= 8'd0;
            lsb       <= 8'd0;
            i2c_start <= 1'b0;
            i2c_next  <= 1'b0;

        end else begin

            //--------------------------------------------------
            // valores por defecto CADA ciclo
            //--------------------------------------------------
            TEMP_done_rdata <= 1'b0;
            i2c_start       <= 1'b0;
            i2c_next        <= 1'b0;

            //--------------------------------------------------
            // =============== SIMULACIÓN =====================
            //--------------------------------------------------
            if (Simulacion) begin

                if (temp_start) begin
                    sim_activo <= 1'b1;
                    sim_cnt    <= 16'd0;
                end

                if (sim_activo) begin
                    sim_cnt <= sim_cnt + 1;

                    if (sim_cnt == 16'd500) begin
                        temp_sim        <= temp_sim + 16'd10;
                        TEMP_data_rdata <= {16'b0, temp_sim};
                        TEMP_done_rdata <= 1'b1;
                        sim_activo      <= 1'b0;
                    end
                end

            //--------------------------------------------------
            // =============== HARDWARE REAL ==================
            //--------------------------------------------------
            end else begin

                case (state)

                    //-----------------------------------------------------
                    S_IDLE: begin
                        if (temp_start) begin
                            i2c_start <= 1'b1;
                            state     <= S_WAIT_MSB;
                        end
                    end

                    //-----------------------------------------------------
                    S_WAIT_MSB: begin
                        if (i2c_done) begin
                            if (!i2c_err) begin
                                msb      <= i2c_data_rd;
                                i2c_next <= 1'b1;
                                state    <= S_WAIT_LSB;
                            end else begin
                                state <= S_IDLE;
                            end
                        end
                    end

                    //-----------------------------------------------------
                    S_WAIT_LSB: begin
                        if (i2c_done) begin
                            lsb   <= i2c_data_rd;
                            state <= S_DONE;
                        end
                    end

                    //-----------------------------------------------------
                    S_DONE: begin
                        TEMP_data_rdata <= {16'b0, msb, lsb};
                        TEMP_done_rdata <= 1'b1;
                        state           <= S_IDLE;
                    end

                    default:
                        state <= S_IDLE;

                endcase
            end
        end
    end
endmodule