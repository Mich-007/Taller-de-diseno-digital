## _____________________________________________________________________________________________________
## CLOCK (100 MHz)
## _____________________________________________________________________________________________________
set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## _____________________________________________________________________________________________________
## SWITCHES (SW0–SW15)
## _____________________________________________________________________________________________________
set_property PACKAGE_PIN J15 [get_ports {sw[0]}];  set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN L16 [get_ports {sw[1]}];  set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property PACKAGE_PIN M13 [get_ports {sw[2]}];  set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
set_property PACKAGE_PIN R15 [get_ports {sw[3]}];  set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]
set_property PACKAGE_PIN R17 [get_ports {sw[4]}];  set_property IOSTANDARD LVCMOS33 [get_ports {sw[4]}]
set_property PACKAGE_PIN T18 [get_ports {sw[5]}];  set_property IOSTANDARD LVCMOS33 [get_ports {sw[5]}]
set_property PACKAGE_PIN U18 [get_ports {sw[6]}];  set_property IOSTANDARD LVCMOS33 [get_ports {sw[6]}]
set_property PACKAGE_PIN R13 [get_ports {sw[7]}];  set_property IOSTANDARD LVCMOS33 [get_ports {sw[7]}]
set_property PACKAGE_PIN T8  [get_ports {sw[8]}];  set_property IOSTANDARD LVCMOS33 [get_ports {sw[8]}]
set_property PACKAGE_PIN U8  [get_ports {sw[9]}];  set_property IOSTANDARD LVCMOS33 [get_ports {sw[9]}]
set_property PACKAGE_PIN R16 [get_ports {sw[10]}]; set_property IOSTANDARD LVCMOS33 [get_ports {sw[10]}]
set_property PACKAGE_PIN T13 [get_ports {sw[11]}]; set_property IOSTANDARD LVCMOS33 [get_ports {sw[11]}]
set_property PACKAGE_PIN H6  [get_ports {sw[12]}]; set_property IOSTANDARD LVCMOS33 [get_ports {sw[12]}]
set_property PACKAGE_PIN U12 [get_ports {sw[13]}]; set_property IOSTANDARD LVCMOS33 [get_ports {sw[13]}]
set_property PACKAGE_PIN U11 [get_ports {sw[14]}]; set_property IOSTANDARD LVCMOS33 [get_ports {sw[14]}]
set_property PACKAGE_PIN V10 [get_ports {sw[15]}]; set_property IOSTANDARD LVCMOS33 [get_ports {sw[15]}]

## _____________________________________________________________________________________________________
## BUTTONS (BTN0–BTN4)
## _____________________________________________________________________________________________________
set_property PACKAGE_PIN P17 [get_ports {btn[0]}]; set_property IOSTANDARD LVCMOS33 [get_ports {btn[0]}]
set_property PACKAGE_PIN M17 [get_ports {btn[1]}]; set_property IOSTANDARD LVCMOS33 [get_ports {btn[1]}]
set_property PACKAGE_PIN M18 [get_ports {btn[2]}]; set_property IOSTANDARD LVCMOS33 [get_ports {btn[2]}]
set_property PACKAGE_PIN P18 [get_ports {btn[3]}]; set_property IOSTANDARD LVCMOS33 [get_ports {btn[3]}]
set_property PACKAGE_PIN N17 [get_ports {btn[4]}]; set_property IOSTANDARD LVCMOS33 [get_ports {btn[4]}]

## _____________________________________________________________________________________________________
## 7-SEGMENT DISPLAY (SEG0–SEG6)
## _____________________________________________________________________________________________________
set_property PACKAGE_PIN T10 [get_ports {seg[0]}]; set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
set_property PACKAGE_PIN R10 [get_ports {seg[1]}]; set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property PACKAGE_PIN K16 [get_ports {seg[2]}]; set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property PACKAGE_PIN K13 [get_ports {seg[3]}]; set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property PACKAGE_PIN P15 [get_ports {seg[4]}]; set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property PACKAGE_PIN T11 [get_ports {seg[5]}]; set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property PACKAGE_PIN L18 [get_ports {seg[6]}]; set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

## _____________________________________________________________________________________________________
## ANODES (AN0–AN7)
## _____________________________________________________________________________________________________
set_property PACKAGE_PIN U13 [get_ports {an[0]}]; set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property PACKAGE_PIN K2  [get_ports {an[1]}]; set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property PACKAGE_PIN T14 [get_ports {an[2]}]; set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property PACKAGE_PIN P14 [get_ports {an[3]}]; set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]
set_property PACKAGE_PIN J14 [get_ports {an[4]}]; set_property IOSTANDARD LVCMOS33 [get_ports {an[4]}]
set_property PACKAGE_PIN T9  [get_ports {an[5]}]; set_property IOSTANDARD LVCMOS33 [get_ports {an[5]}]
set_property PACKAGE_PIN J18 [get_ports {an[6]}]; set_property IOSTANDARD LVCMOS33 [get_ports {an[6]}]
set_property PACKAGE_PIN J17 [get_ports {an[7]}]; set_property IOSTANDARD LVCMOS33 [get_ports {an[7]}]

set_property PACKAGE_PIN E2 [get_ports {rst}]
set_property IOSTANDARD LVCMOS33 [get_ports {rst}]


## _____________________________________________________________________________________________________
## DEBUG LEDS
## _____________________________________________________________________________________________________
##set_property PACKAGE_PIN H17 [get_ports {led[0]}]; set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
##set_property PACKAGE_PIN H7 [get_ports {led[1]}]; set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

## _____________________________________________________________________________________________________
## OPTIONAL: Pull ups for buttons (enable if needed by your board)
## Uncomment the lines below if buttons float when not pressed
## _____________________________________________________________________________________________________
## set_property PULLUP TRUE [get_ports {btn[0]}];  set_property IOSTANDARD LVCMOS33 [get_ports {btn[0]}]
## set_property PULLUP TRUE [get_ports {btn[1]}];  set_property IOSTANDARD LVCMOS33 [get_ports {btn[1]}]
## set_property PULLUP TRUE [get_ports {btn[2]}];  set_property IOSTANDARD LVCMOS33 [get_ports {btn[2]}]
## set_property PULLUP TRUE [get_ports {btn[3]}];  set_property IOSTANDARD LVCMOS33 [get_ports {btn[3]}]
## set_property PULLUP TRUE [get_ports {btn[4]}];  set_property IOSTANDARD LVCMOS33 [get_ports {btn[4]}]

## DEBUG LEDS (usar LD0/LD1 del XDC oficial)
##set_property PACKAGE_PIN X1 [get_ports {led[0]}]; set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
##set_property PACKAGE_PIN Y1 [get_ports {led[1]}]; set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

