set_property PACKAGE_PIN W8 [get_ports clk100mhz1_p]
set_property PACKAGE_PIN W7 [get_ports clk100mhz1_n]

#
#  GBE Port 0
#
set_property PACKAGE_PIN L8 [get_ports clk125mhz2_p]
set_property PACKAGE_PIN L7 [get_ports clk125mhz2_n]
set_property PACKAGE_PIN L3 [get_ports amc_rx0_n]
set_property PACKAGE_PIN L4 [get_ports amc_rx0_p]
set_property PACKAGE_PIN M1 [get_ports amc_tx0_n]
set_property PACKAGE_PIN M2 [get_ports amc_tx0_p]

#
#  SATA Ports 2,3
#
#
#
#  These are only temporary...
#


#
#  Clock signals from MUX
#
set_property PACKAGE_PIN AG32 [get_ports amc502_fpclke_p]
set_property PACKAGE_PIN AH32 [get_ports amc502_fpclke_n]
set_property PACKAGE_PIN AJ32 [get_ports amc502_fpclkf_p]
set_property PACKAGE_PIN AK32 [get_ports amc502_fpclkf_n]
set_property PACKAGE_PIN W26 [get_ports amc502_fpclkg_p]
set_property PACKAGE_PIN W27 [get_ports amc502_fpclkg_n]
set_property PACKAGE_PIN Y28 [get_ports amc502_fpclkh_p]
set_property PACKAGE_PIN Y29 [get_ports amc502_fpclkh_n]

#
#  Clock signals from PLL
#
set_property PACKAGE_PIN F25 [get_ports amc502_fpclka_p]
set_property PACKAGE_PIN F26 [get_ports amc502_fpclka_n]
set_property PACKAGE_PIN G25 [get_ports amc502_fpclkb_p]
set_property PACKAGE_PIN G26 [get_ports amc502_fpclkb_n]
set_property PACKAGE_PIN D20 [get_ports amc502_fpclkc_p]
set_property PACKAGE_PIN D21 [get_ports amc502_fpclkc_n]
set_property PACKAGE_PIN C18 [get_ports amc502_fpclkd_p]
set_property PACKAGE_PIN C19 [get_ports amc502_fpclkd_n]

set_property PACKAGE_PIN G16 [get_ports {user[0]}]
set_property PACKAGE_PIN F18 [get_ports {user[1]}]
set_property PACKAGE_PIN D22 [get_ports {user[2]}]
set_property PACKAGE_PIN H22 [get_ports {user[3]}]
set_property PACKAGE_PIN H23 [get_ports {user[4]}]
set_property PACKAGE_PIN M25 [get_ports {user[5]}]
set_property PACKAGE_PIN J29 [get_ports {user[6]}]

set_property PACKAGE_PIN AC30 [get_ports {nuled[0]}]
set_property PACKAGE_PIN AD31 [get_ports {nuled[1]}]
set_property PACKAGE_PIN AM31 [get_ports {nuled[2]}]
set_property PACKAGE_PIN AD30 [get_ports {nuled[3]}]

set_property PACKAGE_PIN AA24 [get_ports fpga_rx_uart]
set_property PACKAGE_PIN AC24 [get_ports fpga_tx_uart]
set_property PACKAGE_PIN AE34 [get_ports amc502_scl_l1]
set_property PACKAGE_PIN AF34 [get_ports amc502_sda_l1]
set_property PACKAGE_PIN AG18 [get_ports amc502_scl_lllx]
set_property PACKAGE_PIN AG15 [get_ports amc502_sda_lllx]
set_property PACKAGE_PIN H20 [get_ports amc502_pll_rst_n]

set_property IOSTANDARD LVCMOS25 [get_ports {user[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {user[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {user[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {user[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {user[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {user[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {user[6]}]

set_property IOSTANDARD LVCMOS25 [get_ports {nuled[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {nuled[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {nuled[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {nuled[3]}]

set_property IOSTANDARD LVCMOS25 [get_ports fpga_rx_uart]
set_property IOSTANDARD LVCMOS25 [get_ports fpga_tx_uart]
set_property IOSTANDARD LVCMOS25 [get_ports amc502_scl_l1]
set_property IOSTANDARD LVCMOS25 [get_ports amc502_sda_l1]
set_property IOSTANDARD LVCMOS25 [get_ports amc502_scl_lllx]
set_property IOSTANDARD LVCMOS25 [get_ports amc502_sda_lllx]
set_property IOSTANDARD LVCMOS25 [get_ports amc502_pll_rst_n]











































