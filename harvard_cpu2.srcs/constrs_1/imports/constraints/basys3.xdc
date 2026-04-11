## ============================================================
## Basys3 Master Constraints File (for 8-bit Harvard CPU project)
## Xilinx Basys3 — Artix-7 XC7A35T-1CPG236C
## ============================================================

## ---- Clock Signal ----
set_property PACKAGE_PIN W5  [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## ---- Reset Button (BTNU = top button) ----
set_property PACKAGE_PIN T18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

## ---- Push Buttons ----
## BTNC (Center) — Single-step trigger
set_property PACKAGE_PIN U18 [get_ports BTNC]
set_property IOSTANDARD LVCMOS33 [get_ports BTNC]

## BTNL (Left)
set_property PACKAGE_PIN W19 [get_ports BTNL]
set_property IOSTANDARD LVCMOS33 [get_ports BTNL]

## BTNR (Right)
set_property PACKAGE_PIN T17 [get_ports BTNR]
set_property IOSTANDARD LVCMOS33 [get_ports BTNR]

## BTND (Down)
set_property PACKAGE_PIN U17 [get_ports BTND]
set_property IOSTANDARD LVCMOS33 [get_ports BTND]

## ---- Switches ----
set_property PACKAGE_PIN V17 [get_ports {SW[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[0]}]

set_property PACKAGE_PIN V16 [get_ports {SW[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[1]}]

set_property PACKAGE_PIN W16 [get_ports {SW[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[2]}]

set_property PACKAGE_PIN W17 [get_ports {SW[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[3]}]

set_property PACKAGE_PIN W15 [get_ports {SW[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[4]}]

set_property PACKAGE_PIN V15 [get_ports {SW[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[5]}]

set_property PACKAGE_PIN W14 [get_ports {SW[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[6]}]

set_property PACKAGE_PIN W13 [get_ports {SW[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[7]}]

set_property PACKAGE_PIN V2  [get_ports {SW[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[8]}]

set_property PACKAGE_PIN T3  [get_ports {SW[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[9]}]

set_property PACKAGE_PIN T2  [get_ports {SW[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[10]}]

set_property PACKAGE_PIN R3  [get_ports {SW[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[11]}]

set_property PACKAGE_PIN W2  [get_ports {SW[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[12]}]

set_property PACKAGE_PIN U1  [get_ports {SW[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[13]}]

set_property PACKAGE_PIN T1  [get_ports {SW[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[14]}]

set_property PACKAGE_PIN R2  [get_ports {SW[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW[15]}]

## ---- LEDs ----
set_property PACKAGE_PIN U16 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]

set_property PACKAGE_PIN E19 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]

set_property PACKAGE_PIN U19 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]

set_property PACKAGE_PIN V19 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]

set_property PACKAGE_PIN W18 [get_ports {LED[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[4]}]

set_property PACKAGE_PIN U15 [get_ports {LED[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[5]}]

set_property PACKAGE_PIN U14 [get_ports {LED[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[6]}]

set_property PACKAGE_PIN V14 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[7]}]

set_property PACKAGE_PIN V13 [get_ports {LED[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[8]}]

set_property PACKAGE_PIN V3  [get_ports {LED[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[9]}]

set_property PACKAGE_PIN W3  [get_ports {LED[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[10]}]

set_property PACKAGE_PIN U3  [get_ports {LED[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[11]}]

set_property PACKAGE_PIN P3  [get_ports {LED[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[12]}]

set_property PACKAGE_PIN N3  [get_ports {LED[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[13]}]

set_property PACKAGE_PIN P1  [get_ports {LED[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[14]}]

set_property PACKAGE_PIN L1  [get_ports {LED[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[15]}]

## ---- 7-Segment Display Cathodes (seg[6:0] = CA CB CC CD CE CF CG) ----
set_property PACKAGE_PIN W7  [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]

set_property PACKAGE_PIN W6  [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]

set_property PACKAGE_PIN U8  [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]

set_property PACKAGE_PIN V8  [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]

set_property PACKAGE_PIN U5  [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]

set_property PACKAGE_PIN V5  [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]

set_property PACKAGE_PIN U7  [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

## ---- 7-Segment Display Decimal Point ----
set_property PACKAGE_PIN V7  [get_ports dp]
set_property IOSTANDARD LVCMOS33 [get_ports dp]

## ---- 7-Segment Display Anodes (AN[3:0]) ----
set_property PACKAGE_PIN U2  [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]

set_property PACKAGE_PIN U4  [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]

set_property PACKAGE_PIN V4  [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]

set_property PACKAGE_PIN W4  [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]

## ---- Configuration ----
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
