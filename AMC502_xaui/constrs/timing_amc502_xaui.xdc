set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]

#
#  Input clocks
#
create_clock -period 10.000 -name clk100mhz1_p -waveform {0.000 5.000} [get_ports clk100mhz1_p]
create_clock -period 8.000 -name clk125mhz2_p -waveform {0.000 4.000} [get_ports clk125mhz2_p]
create_clock -period 6.400 -name clk156_25mhz2_p -waveform {0.000 3.200} [get_ports clk156_25mhz2_p]
create_clock -period 25.000 -name amc502_fpclka_p -waveform {0.000 12.500} [get_ports amc502_fpclka_p]
create_clock -period 25.000 -name amc502_fpclkb_p -waveform {0.000 12.500} [get_ports amc502_fpclkb_p]
create_clock -period 25.000 -name amc502_fpclkc_p -waveform {0.000 12.500} [get_ports amc502_fpclkc_p]
create_clock -period 25.000 -name amc502_fpclkd_p -waveform {0.000 12.500} [get_ports amc502_fpclkd_p]
create_clock -period 25.000 -name amc502_fpclkg_p -waveform {0.000 12.500} [get_ports amc502_fpclkg_p]

#
#  Input constraints
#
#  amc502_fpclkf_p/n is the slave trigger-encoded system clock input
#    clock recovery is performed on this signal using the AMC502 PLL which produces the 40 MHz amc502_fpclka_p/n clock input
#
set_input_delay -clock amc502_fpclka_p 0.0 [get_ports amc502_fpclkf_p]

#
#  derived clocks
#
create_generated_clock -name clk200mhz \
                       -source [get_pins mmcm_imp/CLKIN1] -multiply_by 2 -add \
                       -master_clock [get_clocks -of_objects [get_pins mmcm_imp/CLKIN1]] [get_pins mmcm_imp/CLKOUT0]
set_clock_groups -asynchronous -group clk100mhz1_p -group clk200mhz

create_generated_clock -name slave_bcoclk_fpclka \
                       -source [get_pins amc502_imp/slave_pll_imp/CLKIN1] -multiply_by 1 -add \
                       [get_pins amc502_imp/slave_pll_imp/CLKOUT0]
create_generated_clock -name slave_bcoclk_fpclkb \
                       -source [get_pins amc502_imp/master_pll_imp/CLKIN2] -multiply_by 1 -add \
                       [get_pins amc502_imp/slave_pll_imp/CLKOUT0]
set_clock_groups -logically_exclusive \
                 -group [get_clocks -include_generated_clocks {slave_bcoclk_fpclka}] \
                 -group [get_clocks -include_generated_clocks {slave_bcoclk_fpclkb}]

create_generated_clock -name slave_sysclk_fpclka \
                       -source [get_pins amc502_imp/slave_pll_imp/CLKIN1] -multiply_by 2 -add \
                       [get_pins amc502_imp/slave_pll_imp/CLKOUT1]
create_generated_clock -name slave_sysclk_fpclkb \
                       -source [get_pins amc502_imp/slave_pll_imp/CLKIN2] -multiply_by 2 -add \
                       [get_pins amc502_imp/slave_pll_imp/CLKOUT1]
set_clock_groups -logically_exclusive \
                 -group [get_clocks -include_generated_clocks {slave_sysclk_fpclka}] \
                 -group [get_clocks -include_generated_clocks {slave_sysclk_fpclkb}]

create_generated_clock -name slave_clk160_fpclka \
                       -source [get_pins amc502_imp/slave_pll_imp/CLKIN1] -multiply_by 2 -add \
                       [get_pins amc502_imp/slave_pll_imp/CLKOUT2]
create_generated_clock -name slave_clk160_fpclkb \
                       -source [get_pins amc502_imp/slave_pll_imp/CLKIN2] -multiply_by 2 -add \
                       [get_pins amc502_imp/slave_pll_imp/CLKOUT2]
set_clock_groups -logically_exclusive \
                 -group [get_clocks -include_generated_clocks {slave_clk160_fpclka}] \
                 -group [get_clocks -include_generated_clocks {slave_clk160_fpclkb}]

create_generated_clock -name slave_bcoclk -source [get_pins amc502_imp/slave_pll_imp/CLKIN1] -multiply_by 1 -add -master_clock amc502_fpclka_p [get_pins amc502_imp/slave_pll_imp/CLKOUT0]

#
#  Unrelated clocks
#
set_clock_groups -asynchronous -group clk100mhz1_p \
                               -group [ get_clocks -include_generated_clocks { \
                                        clk20mhz_out \
                                        clk125mhz2_p clk156_25mhz2_p \
                                        pcs_pma/U0/pcs_pma_block_i/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/RXOUTCLK \
                                        pcs_pma/U0/pcs_pma_block_i/transceiver_inst/gtwizard_inst/U0/gtwizard_i/gt0_GTWIZARD_i/gtxe2_i/TXOUTCLK \
                                        xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/RXOUTCLK \
                                        xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/TXOUTCLK \
                                     } ]
set_clock_groups -asynchronous -group clk100mhz1_p \
                               -group [ get_clocks -include_generated_clocks { \
                                        amc502_fpclka_p amc502_fpclkb_p amc502_fpclkc_p amc502_fpclkd_p amc502_fpclkg_p \
                                      } ]
set_clock_groups -asynchronous -group clk100mhz1_p \
                               -group [ get_clocks { clk40mhz_out clk40mhz_out_1 clk80mhz_out clk80mhz_out_1 clk200mhz_out } ]

set_clock_groups -asynchronous -group clk200mhz \
                               -group [ get_clocks -include_generated_clocks { \
                                        amc502_fpclka_p amc502_fpclkb_p amc502_fpclkc_p amc502_fpclkd_p amc502_fpclkg_p \
                                      } ]
set_clock_groups -asynchronous -group clk200mhz_out \
                               -group [ get_clocks -include_generated_clocks { \
                                        amc502_fpclka_p amc502_fpclkb_p amc502_fpclkc_p amc502_fpclkd_p amc502_fpclkg_p \
                                      } ]

set_clock_groups -asynchronous -group [ get_clocks -include_generated_clocks amc502_fpclka_p ] \
                               -group [ get_clocks -include_generated_clocks { amc502_fpclkb_p amc502_fpclkc_p amc502_fpclkd_p } ]

set_clock_groups -asynchronous -group slave_bcoclk \
                               -group xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/RXOUTCLK
set_clock_groups -asynchronous -group slave_bcoclk_fpclka \
                               -group { xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/RXOUTCLK }
set_clock_groups -asynchronous -group slave_bcoclk_fpclkb \
                               -group { xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/RXOUTCLK }
set_clock_groups -asynchronous -group slave_sysclk_fpclka \
                               -group { clk100mhz1_p }
set_clock_groups -asynchronous -group slave_sysclk_fpclkb \
                               -group { clk100mhz1_p }

set_clock_groups -asynchronous -group slave_clkout0 \
                               -group { clk100mhz1_p xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/RXOUTCLK }
set_clock_groups -asynchronous -group slave_clkout0_1 \
                               -group { clk100mhz1_p xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/RXOUTCLK }
set_clock_groups -asynchronous -group slave_clkout1 \
                               -group { clk100mhz1_p }
set_clock_groups -asynchronous -group slave_clkout0_1 \
                               -group { clk100mhz1_p }

set_clock_groups -asynchronous -group [ get_clocks { clk40mhz_out clk40mhz_out_1 } ] \
                               -group [ get_clocks { slave_bcoclk slave_clkout0 slave_clkout0_1 } ]

set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks slave_fb] -group [get_clocks -include_generated_clocks slave_fb_1]
set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks slave_clkout2] -group [get_clocks -include_generated_clocks slave_clkout2_1]
set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks slave_clkout0_90] -group [get_clocks -include_generated_clocks slave_clkout0_90_1]

#
#  False path because we can't time through the adjustable delay
#
set_false_path -from amc502_fpclkf_p -to amc502_imp/tclka_imp/iddr_imp/D

set_false_path -from [get_clocks xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/RXOUTCLK] -to [get_clocks xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/TXOUTCLK]
set_false_path -from [get_clocks xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/TXOUTCLK] -to [get_clocks xaui_core/gt3_imp/U0/gtwizard_3_init_i/gtwizard_3_i/gt0_gtwizard_3_i/gtxe2_i/RXOUTCLK]

set_multicycle_path 2 -setup -from [ get_clocks slave_clkout0_90_1 ] -to [ get_clocks slave_clkout0 ]
