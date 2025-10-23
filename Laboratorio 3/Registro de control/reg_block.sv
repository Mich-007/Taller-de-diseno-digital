// Se tiene que llamar reg_block.sv
// integra reg_control y reg_data y expone la interfaz hacia FIFOs.
// Uso: conectar este bloque con las FIFOs (instanciadas desde FIFO Generator)
//      y con la Unidad de Control UART.
//___________________________________________________________________________________________

module reg_block #(
  parameter int WIDTH = 32,
  parameter int CNT_WIDTH = 9
)(
  input  logic                 i_clk,
  input  logic                 i_rst_n,

  // Interfaz agente (bus 32)
  input  logic                 i_reg_sel,
  input  logic                 i_wr,
  input  logic                 i_rd,
  input  logic [WIDTH-1:0]     i_reg_wr_data,
  output logic [WIDTH-1:0]     o_reg_rd_data,

  // Señales FIFO TX
  output logic                 o_fifo_tx_push_en,
  output logic [7:0]           o_fifo_tx_push_data,
  input  logic [CNT_WIDTH-1:0] i_fifo_tx_count,
  input  logic                 i_fifo_tx_full,

  // Señales FIFO RX
  input  logic [7:0]           i_fifo_rx_data,
  input  logic                 i_fifo_rx_valid,
  output logic                 o_fifo_rx_pop_en,

  // S/C/DC bus (control interno)
  input  logic                 i_scdc_set_send,
  input  logic                 i_scdc_clear_send,
  input  logic                 i_scdc_set_read,
  input  logic                 i_scdc_clear_read,

  // Salidas de estado/flags hacia el exterior/hardware para indicadores
  output logic [CNT_WIDTH-1:0] o_bytes_tx,
  output logic [CNT_WIDTH-1:0] o_bytes_rx,
  output logic                 o_ftxf,
  output logic                 o_rxav,
  output logic                 o_send_req,     // petición de enviar generada por reg_control
  output logic                 o_read_req      // petición de leer generada por reg_control
);

  // Wires intermedias
  logic [WIDTH-1:0] rd_data_control;
  logic [WIDTH-1:0] rd_data_data;

  // Instanciación de reg_control
  reg_control #(
    .WIDTH(WIDTH),
    .CNT_WIDTH(CNT_WIDTH)
  ) u_reg_control (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_reg_sel(i_reg_sel),
    .i_wr(i_wr),
    .i_rd(i_rd),
    .i_reg_wr_data(i_reg_wr_data),
    .o_reg_rd_data(rd_data_control),
    .i_fifo_tx_count(i_fifo_tx_count),
    .i_fifo_rx_count(o_bytes_rx), // conectado a la salida reflejada de reg_control
    .i_fifo_tx_full(i_fifo_tx_full),
    .i_fifo_rx_not_empty(i_fifo_rx_valid),
    .i_scdc_set_send(i_scdc_set_send),
    .i_scdc_clear_send(i_scdc_clear_send),
    .i_scdc_set_read(i_scdc_set_read),
    .i_scdc_clear_read(i_scdc_clear_read),
    .o_send_req(o_send_req),
    .o_read_req(o_read_req),
    .o_bytes_tx(o_bytes_tx),
    .o_bytes_rx(o_bytes_rx),
    .o_ftxf(o_ftxf),
    .o_rxav(o_rxav)
  );

  // Instanciación de reg_data
  reg_data #(
    .WIDTH(WIDTH),
    .CNT_WIDTH(CNT_WIDTH)
  ) u_reg_data (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_reg_sel(i_reg_sel),
    .i_wr(i_wr),
    .i_rd(i_rd),
    .i_reg_wr_data(i_reg_wr_data),
    .o_reg_rd_data(rd_data_data),
    .o_fifo_tx_push_en(o_fifo_tx_push_en),
    .o_fifo_tx_push_data(o_fifo_tx_push_data),
    .i_fifo_tx_count(i_fifo_tx_count),
    .i_fifo_tx_full(i_fifo_tx_full),
    .i_fifo_rx_data(i_fifo_rx_data),
    .i_fifo_rx_valid(i_fifo_rx_valid),
    .o_fifo_rx_pop_en(o_fifo_rx_pop_en),
    .o_last_write_count(),            // no usado en wrapper, útil en testbench
    .i_read_consume_done(i_scdc_clear_read) // uso: cuando UC limpia leer, consideramos consumo
  );

  // Selección de lectura: si reg_sel==0 y rd, devolvemos registro de control
  // si reg_sel==1 y rd, devolvemos registro de datos. Si nadie lee, 0.
  always_comb begin
    if ((i_reg_sel == 1'b0) && i_rd) begin
      o_reg_rd_data = rd_data_control;
    end else if ((i_reg_sel == 1'b1) && i_rd) begin
      o_reg_rd_data = rd_data_data;
    end else begin
      o_reg_rd_data = '0;
    end
  end

endmodule
