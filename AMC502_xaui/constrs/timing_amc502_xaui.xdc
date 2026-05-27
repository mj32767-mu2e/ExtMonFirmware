set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]

#
#  Input clocks
#
create_clock -period 10.000 -name clk100mhz1_p -waveform {0.000 5.000} [get_ports clk100mhz1_p]
create_clock -period 8.000 -name clk125mhz2_p -waveform {0.000 4.000} [get_ports clk125mhz2_p]
create_clock -period 25.000 -name amc502_fpclka_p -waveform {0.000 12.500} [get_ports amc502_fpclka_p]
create_clock -period 25.000 -name amc502_fpclkb_p -waveform {0.000 12.500} [get_ports amc502_fpclkb_p]
create_clock -period 25.000 -name amc502_fpclkc_p -waveform {0.000 12.500} [get_ports amc502_fpclkc_p]
create_clock -period 25.000 -name amc502_fpclkd_p -waveform {0.000 12.500} [get_ports amc502_fpclkd_p]
create_clock -period 12.500 -name amc502_fpclkf_p -waveform {0.000 6.250} [get_ports amc502_fpclkf_p]
create_clock -period 6.400 -name clk156_25mhz2_p -waveform {0.000 3.200} [get_ports clk156_25mhz2_p]


#
#  derived clocks
#
create_generated_clock -name master_sysclk -source [get_pins amc502_imp/master_pll_imp/CLKIN1] -multiply_by 2 -add -master_clock amc502_fpclkb_p [get_pins amc502_imp/master_pll_imp/CLKOUT1]
create_generated_clock -name master_bcoclk -source [get_pins amc502_imp/master_pll_imp/CLKIN1] -multiply_by 1 -add -master_clock amc502_fpclkb_p [get_pins amc502_imp/master_pll_imp/CLKOUT0]
create_generated_clock -name slave_sysclk -source [get_pins amc502_imp/slave_pll_imp/CLKIN1] -multiply_by 2 -add -master_clock amc502_fpclka_p [get_pins amc502_imp/slave_pll_imp/CLKOUT1]
create_generated_clock -name slave_bcoclk -source [get_pins amc502_imp/slave_pll_imp/CLKIN1] -multiply_by 1 -add -master_clock amc502_fpclka_p [get_pins amc502_imp/slave_pll_imp/CLKOUT0]

#
#  Inputs
#
set_input_delay -clock slave_sysclk -max 3.000 [get_ports amc502_fpclkg_p]
set_input_delay -clock slave_sysclk -min -1.000 [get_ports amc502_fpclkg_p]
set_input_delay -clock slave_sysclk -clock_fall -max -add_delay 3.000 [get_ports amc502_fpclkg_p]
set_input_delay -clock slave_sysclk -clock_fall -min -add_delay -1.000 [get_ports amc502_fpclkg_p]

#
#  Unrelated clocks
#
set_clock_groups -asynchronous -group [get_clocks clk125mhz2_p] -group [get_clocks clk100mhz1_p]
set_clock_groups -asynchronous -group [get_clocks clk156_25mhz2_p] -group [get_clocks clk100mhz1_p]

set_clock_groups -asynchronous -group [get_clocks amc502_fpclka_p] -group [get_clocks clk100mhz1_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclkb_p] -group [get_clocks clk100mhz1_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclkc_p] -group [get_clocks clk100mhz1_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclkd_p] -group [get_clocks clk100mhz1_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclkf_p] -group [get_clocks clk100mhz1_p]

set_clock_groups -asynchronous -group [get_clocks amc502_fpclka_p] -group [get_clocks amc502_fpclkb_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclka_p] -group [get_clocks amc502_fpclkc_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclka_p] -group [get_clocks amc502_fpclkd_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclkb_p] -group [get_clocks amc502_fpclka_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclkb_p] -group [get_clocks amc502_fpclkc_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclkb_p] -group [get_clocks amc502_fpclkd_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclkc_p] -group [get_clocks amc502_fpclka_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclkc_p] -group [get_clocks amc502_fpclkb_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclkc_p] -group [get_clocks amc502_fpclkd_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclkd_p] -group [get_clocks amc502_fpclka_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclkd_p] -group [get_clocks amc502_fpclkb_p]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclkd_p] -group [get_clocks amc502_fpclkc_p]

set_clock_groups -asynchronous -group [get_clocks master_bcoclk] -group [get_clocks slave_sysclk]
set_clock_groups -asynchronous -group [get_clocks amc502_fpclkf_p] -group [get_clocks slave_sysclk]

set_clock_groups -asynchronous -group [get_clocks clk100mhz1_p] -group [get_clocks master_bcoclk]
set_clock_groups -asynchronous -group [get_clocks clk100mhz1_p] -group [get_clocks slave_bcoclk]
set_clock_groups -asynchronous -group [get_clocks clk100mhz1_p] -group [get_clocks slave_sysclk]
set_clock_groups -asynchronous -group [get_clocks master_bcoclk] -group [get_clocks clk100mhz1_p]
set_clock_groups -asynchronous -group [get_clocks master_sysclk] -group [get_clocks clk100mhz1_p]
set_clock_groups -asynchronous -group [get_clocks slave_bcoclk] -group [get_clocks clk100mhz1_p]
set_clock_groups -asynchronous -group [get_clocks slave_sysclk] -group [get_clocks clk100mhz1_p]


set_multicycle_path -from [get_clocks master_bcoclk] -to [get_clocks master_sysclk] 2


set_false_path -from [get_clocks xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/RXOUTCLK] -to [get_clocks slave_bcoclk]
set_false_path -from [get_clocks xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/RXOUTCLK] -to [get_clocks xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/TXOUTCLK]
set_false_path -from [get_clocks xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/TXOUTCLK] -to [get_clocks xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/RXOUTCLK]


set_false_path -from [get_clocks slave_bcoclk] -to [get_clocks -of_objects [get_pins amc502_imp/master_pll_imp/CLKOUT2]]

set_false_path -from [get_clocks clk100mhz1_p] -to [get_clocks -of_objects [get_pins amc502_imp/master_pll_imp/CLKOUT2]]
set_false_path -from [get_clocks clk100mhz1_p] -to [get_clocks -of_objects [get_pins pcs_pma/U0/core_clocking_i/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins pcs_pma/U0/core_clocking_i/mmcm_adv_inst/CLKOUT0]] -to [get_clocks clk100mhz1_p]
set_false_path -from [get_clocks -of_objects [get_pins amc502_imp/master_pll_imp/CLKOUT2]] -to [get_clocks clk100mhz1_p]
set_false_path -from [get_clocks -of_objects [get_pins amc502_imp/slave_pll_imp/CLKOUT3] -filter {IS_GENERATED && MASTER_CLOCK == amc502_fpclka_p}] -to [get_clocks clk100mhz1_p]
set_false_path -from [get_clocks -of_objects [get_pins amc502_imp/slave_pll_imp/CLKOUT3] -filter {IS_GENERATED && MASTER_CLOCK == master_bcoclk}] -to [get_clocks clk100mhz1_p]

create_clock -period 100.000 -name amc502_fpclkg_p -waveform {0.000 50.000} [get_ports amc502_fpclkg_p]
set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks slave_fb] -group [get_clocks -include_generated_clocks slave_fb_1]
set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks slave_clkout2] -group [get_clocks -include_generated_clocks slave_clkout2_1]
set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks slave_clkout0_90] -group [get_clocks -include_generated_clocks slave_clkout0_90_1]

set_false_path -from [get_clocks clk100mhz1_p] -to [get_clocks xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/RXOUTCLK]
set_false_path -from [get_clocks xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/RXOUTCLK] -to [get_clocks clk100mhz1_p]
set_false_path -from [get_clocks amc502_fpclkg_p] -to [get_clocks clk100mhz1_p]
