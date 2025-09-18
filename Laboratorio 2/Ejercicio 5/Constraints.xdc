set_property PACKAGE_PIN E3         [get_ports clk_100]
set_property IOSTANDARD LVCMOS33    [get_ports clk_100]
create_clock -name sys_clk -period 10.000 [get_ports clk_100]

# Reset (botón, activo alto) en P17
set_property PACKAGE_PIN P17        [get_ports reset]
set_property IOSTANDARD LVCMOS33    [get_ports reset]

## Switches
set_property PACKAGE_PIN V10 [get_ports {SW[0]}];  set_property IOSTANDARD LVCMOS33 [get_ports {SW[0]}]
set_property PACKAGE_PIN U11 [get_ports {SW[1]}];  set_property IOSTANDARD LVCMOS33 [get_ports {SW[1]}]
set_property PACKAGE_PIN U12 [get_ports {SW[2]}];  set_property IOSTANDARD LVCMOS33 [get_ports {SW[2]}]
set_property PACKAGE_PIN H6  [get_ports {SW[3]}];  set_property IOSTANDARD LVCMOS33 [get_ports {SW[3]}]
set_property PACKAGE_PIN T13 [get_ports {SW[4]}];  set_property IOSTANDARD LVCMOS33 [get_ports {SW[4]}]
set_property PACKAGE_PIN R16 [get_ports {SW[5]}];  set_property IOSTANDARD LVCMOS33 [get_ports {SW[5]}]
set_property PACKAGE_PIN U8  [get_ports {SW[6]}];  set_property IOSTANDARD LVCMOS33 [get_ports {SW[6]}]
set_property PACKAGE_PIN T8  [get_ports {SW[7]}];  set_property IOSTANDARD LVCMOS33 [get_ports {SW[7]}]
set_property PACKAGE_PIN R13 [get_ports {SW[8]}];  set_property IOSTANDARD LVCMOS33 [get_ports {SW[8]}]
set_property PACKAGE_PIN U18 [get_ports {SW[9]}];  set_property IOSTANDARD LVCMOS33 [get_ports {SW[9]}]
set_property PACKAGE_PIN T18 [get_ports {SW[10]}]; set_property IOSTANDARD LVCMOS33 [get_ports {SW[10]}]
set_property PACKAGE_PIN R17 [get_ports {SW[11]}]; set_property IOSTANDARD LVCMOS33 [get_ports {SW[11]}]
set_property PACKAGE_PIN R15 [get_ports {SW[12]}]; set_property IOSTANDARD LVCMOS33 [get_ports {SW[12]}]
set_property PACKAGE_PIN M13 [get_ports {SW[13]}]; set_property IOSTANDARD LVCMOS33 [get_ports {SW[13]}]
set_property PACKAGE_PIN L16 [get_ports {SW[14]}]; set_property IOSTANDARD LVCMOS33 [get_ports {SW[14]}]
set_property PACKAGE_PIN J15 [get_ports {SW[15]}]; set_property IOSTANDARD LVCMOS33 [get_ports {SW[15]}]

## Botones que controlan el grupo de Switches
## BOTONES (BTN0-BTN3)
## =======================
set_property PACKAGE_PIN M18 [get_ports {BTN[0]}]; set_property IOSTANDARD LVCMOS33 [get_ports {BTN[0]}]
set_property PACKAGE_PIN N17 [get_ports {BTN[1]}]; set_property IOSTANDARD LVCMOS33 [get_ports {BTN[1]}]
set_property PACKAGE_PIN M17 [get_ports {BTN[2]}]; set_property IOSTANDARD LVCMOS33 [get_ports {BTN[2]}]
set_property PACKAGE_PIN P18 [get_ports {BTN[3]}]; set_property IOSTANDARD LVCMOS33 [get_ports {BTN[3]}]
# Añadir aquí los pines correctos de btn[2] y btn[3] según tu placa
#set_property PACKAGE_PIN <PIN> [get_ports {btn[2]}]; set_property IOSTANDARD LVCMOS33 [get_ports {btn[2]}]
#set_property PACKAGE_PIN <PIN> [get_ports {btn[3]}]; set_property IOSTANDARD LVCMOS33 [get_ports {btn[3]}]

## =======================
## LEDS (LD0-LD15)
## =======================
set_property PACKAGE_PIN H17 [get_ports {LED[15]}]; set_property IOSTANDARD LVCMOS33 [get_ports {LED[15]}]
set_property PACKAGE_PIN K15 [get_ports {LED[14]}]; set_property IOSTANDARD LVCMOS33 [get_ports {LED[14]}]
set_property PACKAGE_PIN J13 [get_ports {LED[13]}]; set_property IOSTANDARD LVCMOS33 [get_ports {LED[13]}]
set_property PACKAGE_PIN N14 [get_ports {LED[12]}]; set_property IOSTANDARD LVCMOS33 [get_ports {LED[12]}]
set_property PACKAGE_PIN R18 [get_ports {LED[11]}]; set_property IOSTANDARD LVCMOS33 [get_ports {LED[11]}]
set_property PACKAGE_PIN V17 [get_ports {LED[10]}]; set_property IOSTANDARD LVCMOS33 [get_ports {LED[10]}]
set_property PACKAGE_PIN U17 [get_ports {LED[9]}];  set_property IOSTANDARD LVCMOS33 [get_ports {LED[9]}]
set_property PACKAGE_PIN U16 [get_ports {LED[8]}];  set_property IOSTANDARD LVCMOS33 [get_ports {LED[8]}]
set_property PACKAGE_PIN V16 [get_ports {LED[7]}];  set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]
set_property PACKAGE_PIN T15 [get_ports {LED[6]}];  set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]
set_property PACKAGE_PIN U14 [get_ports {LED[5]}];  set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]
set_property PACKAGE_PIN T16 [get_ports {LED[4]}];  set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]
set_property PACKAGE_PIN V15 [get_ports {LED[3]}];  set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]
set_property PACKAGE_PIN V14 [get_ports {LED[2]}];  set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]
set_property PACKAGE_PIN V12 [get_ports {LED[1]}];  set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]
set_property PACKAGE_PIN V11 [get_ports {LED[0]}];  set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]


##  nodos de display 7 segmentos 
set_property PACKAGE_PIN J17 [get_ports {AN[7]}]; set_property IOSTANDARD LVCMOS33 [get_ports {AN[7]}]
set_property PACKAGE_PIN J18 [get_ports {AN[6]}]; set_property IOSTANDARD LVCMOS33 [get_ports {AN[6]}]
set_property PACKAGE_PIN T9  [get_ports {AN[5]}]; set_property IOSTANDARD LVCMOS33 [get_ports {AN[5]}]
set_property PACKAGE_PIN J14 [get_ports {AN[4]}]; set_property IOSTANDARD LVCMOS33 [get_ports {AN[4]}]
set_property PACKAGE_PIN P14 [get_ports {AN[3]}]; set_property IOSTANDARD LVCMOS33 [get_ports {AN[3]}]
set_property PACKAGE_PIN T14 [get_ports {AN[2]}]; set_property IOSTANDARD LVCMOS33 [get_ports {AN[2]}]
set_property PACKAGE_PIN K2  [get_ports {AN[1]}]; set_property IOSTANDARD LVCMOS33 [get_ports {AN[1]}]
set_property PACKAGE_PIN U13 [get_ports {AN[0]}]; set_property IOSTANDARD LVCMOS33 [get_ports {AN[0]}]

## Display de 7 segmentos
set_property PACKAGE_PIN T10 [get_ports {SEG[0]}]; set_property IOSTANDARD LVCMOS33 [get_ports {SEG[0]}]
set_property PACKAGE_PIN R10 [get_ports {SEG[1]}]; set_property IOSTANDARD LVCMOS33 [get_ports {SEG[1]}]
set_property PACKAGE_PIN K16 [get_ports {SEG[2]}]; set_property IOSTANDARD LVCMOS33 [get_ports {SEG[2]}]
set_property PACKAGE_PIN K13 [get_ports {SEG[3]}]; set_property IOSTANDARD LVCMOS33 [get_ports {SEG[3]}]
set_property PACKAGE_PIN P15 [get_ports {SEG[4]}]; set_property IOSTANDARD LVCMOS33 [get_ports {SEG[4]}]
set_property PACKAGE_PIN T11 [get_ports {SEG[5]}]; set_property IOSTANDARD LVCMOS33 [get_ports {SEG[5]}]
set_property PACKAGE_PIN L18 [get_ports {SEG[6]}]; set_property IOSTANDARD LVCMOS33 [get_ports {SEG[6]}]
set_property PACKAGE_PIN H15 [get_ports {SEG[7]}]; set_property IOSTANDARD LVCMOS33 [get_ports {SEG[7]}]
