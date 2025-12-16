## 吃豆人 - 引脚约束文件
## xc7a100t

## 时钟
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]

## 复位按钮
set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports rstn]

## UART
set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports uart_rx]

## VGA
set_property -dict { PACKAGE_PIN A3 IOSTANDARD LVCMOS33 } [get_ports {red[0]}]
set_property -dict { PACKAGE_PIN B4 IOSTANDARD LVCMOS33 } [get_ports {red[1]}]
set_property -dict { PACKAGE_PIN C5 IOSTANDARD LVCMOS33 } [get_ports {red[2]}]
set_property -dict { PACKAGE_PIN A4 IOSTANDARD LVCMOS33 } [get_ports {red[3]}]
set_property -dict { PACKAGE_PIN C6 IOSTANDARD LVCMOS33 } [get_ports {green[0]}]
set_property -dict { PACKAGE_PIN A5 IOSTANDARD LVCMOS33 } [get_ports {green[1]}]
set_property -dict { PACKAGE_PIN B6 IOSTANDARD LVCMOS33 } [get_ports {green[2]}]
set_property -dict { PACKAGE_PIN A6 IOSTANDARD LVCMOS33 } [get_ports {green[3]}]
set_property -dict { PACKAGE_PIN B7 IOSTANDARD LVCMOS33 } [get_ports {blue[0]}]
set_property -dict { PACKAGE_PIN C7 IOSTANDARD LVCMOS33 } [get_ports {blue[1]}]
set_property -dict { PACKAGE_PIN D7 IOSTANDARD LVCMOS33 } [get_ports {blue[2]}]
set_property -dict { PACKAGE_PIN D8 IOSTANDARD LVCMOS33 } [get_ports {blue[3]}]
set_property -dict { PACKAGE_PIN B11 IOSTANDARD LVCMOS33 } [get_ports hs]
set_property -dict { PACKAGE_PIN B12 IOSTANDARD LVCMOS33 } [get_ports vs]

## LED
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 } [get_ports {led[2]}]
set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports {led[3]}]
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 } [get_ports {led[4]}]
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports {led[5]}]
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports {led[6]}]
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {led[7]}]
