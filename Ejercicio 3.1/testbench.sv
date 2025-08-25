timescale 1ns/1ps

module testbench_FPGA_led;
  logic [15:0] sw;
  logic [3:0] btn;
  wire [15:0] led;

  FPGA_led_switch dut (
    .sv(sw),
    .btn(btn),
    .led(led),

  );

  task show_state;
    $display ("t=% 0t | btn=%b | sw[15:12]=%h sw[11:8]=%h sw[7:4]=%h sw[3:0]=%h | led[15:12]=%h led[11:8]=%h led[7:4]=%h led[3:0]=%h",
         $time, btn,
              sw[15:12], sw[11:8], sw[7:4], sw[3:0],
              led[15:12], led[11:8], led[7:4], led[3:0]
             
             );
  endtask

  initial begin 
    $dumpfile("testbench_FPGA_led.vcd");
    $dumpvars(0, testbench_FPGA_led);

    $display("======== INICIO DE TESTBENCH==========");

    sw=16¨hFFFF; btn = 4´b0000;#10;
    show_state ();

    btn = 4´b0001; #10;
    show_state ();

    btn = 4´b0100; #10;
    show_state ();

    btn = 4´b0010; #10;
    show_state ();

    btn = 4´b1000; #10;
    show_state ();

    btn = 4´b0101; #10;
    show_state ();

    sw=16¨hA5A5; btn = 4´b0000;#10;
    show_state ();

    sw=16¨h0F0F; btn = 4´b0010;#10;
    show_state ();

    sw=16¨hAAAA; btn = 4´b1000;#10;
    show_state ();

    $display("=========FIN DE TESTBENCH===========");
    #10 $FINISH;

  end

endmodule

    

    
