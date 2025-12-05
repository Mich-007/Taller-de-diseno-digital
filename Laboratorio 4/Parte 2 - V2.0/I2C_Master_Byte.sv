`timescale 1ns/1ps
module I2C_Master_Byte #(
    parameter int CLK_FREQ = 100_000_000,
    parameter int I2C_FREQ = 100_000
)(
    input  logic clk,
    input  logic reset,

    input  logic       start,
    input  logic [6:0] addr,
    input  logic       rw,         // 0=write, 1=read
    input  logic [7:0] data_wr,
    input  logic       next,       // seguir leyendo bytes

    output logic [7:0] data_rd,
    output logic       busy,
    output logic       done,
    output logic       ack_error,

    output logic scl,
    inout  tri   sda
);

    //-------------------------------------------------
    // Clock Divider
    //-------------------------------------------------
    localparam int DIV = CLK_FREQ/(I2C_FREQ*4);

    logic [$clog2(DIV)-1:0] cnt;
    logic tick;
    logic [1:0] phase;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt   <= 0;
            tick  <= 0;
            phase <= 0;
        end else begin
            if (cnt == DIV-1) begin
                cnt   <= 0;
                tick  <= 1;
                phase <= phase + 1;
            end else begin
                cnt  <= cnt + 1;
                tick <= 0;
            end
        end
    end

    //-------------------------------------------------
    // SDA open-drain
    //-------------------------------------------------
    logic sda_oe;
    assign sda = (sda_oe) ? 1'b0 : 1'bz;
    wire  sda_in = sda;

    //-------------------------------------------------
    // Sync SCL
    //-------------------------------------------------
    logic scl_reg;
    assign scl = scl_reg;

    //-------------------------------------------------
    // FSM
    //-------------------------------------------------
    typedef enum logic [3:0] {
        ST_IDLE,
        ST_START,
        ST_ADDR,
        ST_ADDR_ACK,
        ST_READ_BYTE,
        ST_READ_ACK,
        ST_STOP
    } state_t;

    state_t state, nstate;

    logic [7:0] shreg;
    logic [3:0] bit_cnt;

    logic rw_reg;
    logic rep_read;

    //-------------------------------------------------
    // Sequential process (ONLY FF)
    //-------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= ST_IDLE;
            shreg     <= 0;
            bit_cnt   <= 4'd7;
            data_rd   <= 8'd0;
            busy      <= 1'b0;
            done      <= 1'b0;
            ack_error <= 1'b0;
            rw_reg    <= 1'b0;
            scl_reg   <= 1'b1;
            sda_oe    <= 1'b0;
        end else begin
            done <= 1'b0;

            if (tick) begin
                state <= nstate;

                case (state)

                    ST_IDLE: begin
                        busy    <= 1'b0;
                        scl_reg <= 1'b1;
                        sda_oe  <= 1'b0;

                        if (start) begin
                            busy      <= 1'b1;
                            rw_reg    <= rw;
                            shreg     <= {addr, rw};
                            bit_cnt  <= 4'd7;
                        end
                    end

                    ST_START: begin
                        if (phase == 0) begin
                            scl_reg <= 1'b1;
                            sda_oe  <= 1'b1;
                        end
                        if (phase == 2)
                            scl_reg <= 1'b0;
                    end

                    ST_ADDR,
                    ST_READ_BYTE: begin
                        case (phase)
                            0: begin
                                scl_reg <= 0;
                                sda_oe  <= ~rw_reg;
                                shreg <= {shreg[6:0],1'b0};
                            end
                            1: scl_reg <= 1;
                            2: if (rw_reg) shreg <= {shreg[6:0], sda_in};
                            3: begin
                                scl_reg <= 0;
                                if (bit_cnt != 0)
                                    bit_cnt <= bit_cnt - 1;
                            end
                        endcase
                    end

                    ST_ADDR_ACK,
                    ST_READ_ACK: begin
                        case (phase)
                            0: begin
                                scl_reg <= 0;
                                sda_oe <= (state==ST_READ_ACK) ? ~rep_read : 1'b0;
                            end
                            1: scl_reg <= 1'b1;
                            2: if (state==ST_ADDR_ACK)
                                   ack_error <= sda_in;
                            3: scl_reg <= 1'b0;
                        endcase
                    end

                    ST_STOP: begin
                        case (phase)
                            0: begin
                                scl_reg <= 0;
                                sda_oe <= 1'b1;
                            end
                            1: scl_reg <= 1;
                            2: sda_oe <= 1'b0;
                            3: begin
                                busy   <= 0;
                                done   <= 1;
                                data_rd <= shreg;
                            end
                        endcase
                    end

                endcase

            end
        end
    end

    //-------------------------------------------------
    // Combinational next-state
    //-------------------------------------------------
    always_comb begin

        nstate = state;
        rep_read = 1'b0;

        case (state)

            ST_IDLE:
                if (start)
                    nstate = ST_START;

            ST_START:
                if (phase == 2'd3)
                    nstate = ST_ADDR;

            ST_ADDR:
                if (phase == 2'd3 && bit_cnt == 0)
                    nstate = ST_ADDR_ACK;

            ST_ADDR_ACK:
                if (phase == 2'd3)
                    nstate = ack_error ? ST_STOP : ST_READ_BYTE;

            ST_READ_BYTE:
                if (phase == 2'd3 && bit_cnt == 0)
                    nstate = ST_READ_ACK;

            ST_READ_ACK: begin
                rep_read = next;
                if (phase == 2'd3)
                    nstate = next ? ST_READ_BYTE : ST_STOP;
            end

            ST_STOP:
                if (phase == 2'd3)
                    nstate = ST_IDLE;

            default:
                nstate = ST_IDLE;
        endcase
    end
endmodule