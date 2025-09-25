# Reloj de entrada de 100 MHz (pin E3)
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports clk_0]

# Señales de salida del CLK
set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33 } [get_ports { clk_10Mhz }]; #IO_L20N_T3_A19_15 Sch=ja[1]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { clk_100Mhz }]; #IO_L21N_T3_DQS_A18_15 Sch=ja[2]

# Reset
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { rst_0 }]; #IO_L12P_T1_MRCC_14 Sch=btnl
