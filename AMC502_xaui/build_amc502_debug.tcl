set_part xc7k420tffg1156-2
create_project -in_memory -part xc7k420tffg1156-2
set_property parent.project_path ./amc502_xaui.xpr [current_project]
set_property target_language VHDL [current_project]
set_property ip_output_repo ./ip [current_project]
set_property ip_cache_permissions {read write} [current_project]

read_ip ./ip/microblaze_mcs_0/microblaze_mcs_0.xci
export_ip_user_files -of_objects  [get_files ./ip/microblaze_mcs_0/microblaze_mcs_0.xci] -sync -no_script -force -quiet
generate_target all [get_files ./ip/microblaze_mcs_0/microblaze_mcs_0.xci]

read_ip ./ip/gig_ethernet_pcs_pma_0/gig_ethernet_pcs_pma_0.xci
export_ip_user_files -of_objects  [get_files ./ip/gig_ethernet_pcs_pma_0/gig_ethernet_pcs_pma_0.xci] -sync -no_script -force -quiet
generate_target all [get_files ./ip/gig_ethernet_pcs_pma_0/gig_ethernet_pcs_pma_0.xci]

read_ip ./ip/gtwizard_3/gtwizard_3.xcix
export_ip_user_files -of_objects  [get_files ./ip/gtwizard_3/gtwizard_3.xcix] -sync -no_script -force -quiet
generate_target all [get_files ./ip/gtwizard_3/gtwizard_3.xcix]

read_ip ./ip/gtwizard_4/gtwizard_4.xcix
export_ip_user_files -of_objects  [get_files ./ip/gtwizard_4/gtwizard_4.xcix] -sync -no_script -force -quiet
generate_target all [get_files ./ip/gtwizard_4/gtwizard_4.xcix]

read_vhdl ./sources/top_amc502_xaui.vhd
read_vhdl -library hep337dev -verbose { ../Sources/iobus.vhd ../Sources/iobus_interface.vhd }
read_vhdl -library hep337dev -verbose { \
  ../Sources/amc502.vhd \
  ../Sources/amc502_interface.vhd \
  ../Sources/i2c.vhd \
  ../Sources/i2c_slave.vhd \
  ../Sources/tclkb_driver.vhd \
  ../Sources/tclka_receiver.vhd \
  ../Sources/tclka_counter.vhd \
  ../Sources/latch_generator.vhd \
  ../Sources/clkfreq.vhd \
}
read_vhdl -library hep337dev -verbose { \
  ../Sources/gbe.vhd \
  ../Sources/gbe_interface.vhd \
  ../Sources/crc32.vhd \
  ../Sources/cksum.vhd \
  ../Sources/add8.vhd \
  ../Sources/ipbuf.vhd \
  ../Sources/ethernet.vhd \
  ../Sources/arp.vhd \
  ../Sources/arptab.vhd \
  ../Sources/ip.vhd \
  ../Sources/icmp.vhd \
  ../Sources/udp.vhd \
  ../Sources/udpbuffer.vhd \
  ../Sources/txether.vhd \
  ../Sources/ipheader.vhd \
  ../Sources/arprep.vhd \
  ../Sources/arpreq.vhd \
  ../Sources/icmprep.vhd \
  ../Sources/txbuffer.vhd \
  ../Sources/sendpkt.vhd \
  ../Sources/gbe_stream_buffer.vhd \
  ../Sources/streampkt.vhd \
}
read_vhdl -library hep337dev -verbose { \
  ../Sources/xaui.vhd \
  ../Sources/xaui_interface.vhd \
  ../Sources/xaui_xgmii.vhd \
  ../Sources/crc32x64.vhd \
  ../Sources/crc32x64_slice.vhd \
  ../Sources/xaui_ethernet.vhd \
  ../Sources/xaui_arp.vhd \
  ../Sources/xaui_icmp.vhd \
  ../Sources/xaui_arprep.vhd \
  ../Sources/xaui_arpreq.vhd \
  ../Sources/xaui_icmprep.vhd \
  ../Sources/xaui_icmpreq.vhd \
  ../Sources/xaui_udp.vhd \
  ../Sources/xaui_udpbuffer.vhd \
  ../Sources/xaui_trigger.vhd \
  ../Sources/xaui_txbuffer.vhd \
  ../Sources/xaui_sendpkt.vhd \
  ../Sources/xaui_stream_buffer.vhd \
  ../Sources/xaui_streampkt.vhd \
  ../Sources/xaui_arbiter.vhd \
}
read_vhdl -library hep337dev -verbose { \
  ../Sources/utilities.vhd \
  ../Sources/lfsr_n.vhd \
}

synth_ip [get_ips microblaze_mcs_0]
synth_ip [get_ips gig_ethernet_pcs_pma_0]
synth_ip [get_ips gtwizard_3]
synth_ip [get_ips gtwizard_4]

synth_design -top top_amc502_xaui -part xc7k420tffg1156-2

write_checkpoint -force -noxdef top_amc502_xaui_synth.dcp
report_utilization -file top_amc502_xaui_utilization.log -hierarchical -hierarchical_depth 8

read_xdc ./constrs/pins_amc502.xdc
read_xdc ./constrs/pins_xaui.xdc
read_xdc ./constrs/timing_amc502_xaui.xdc
add_files top_amc502_xaui_synth.dcp

all_clocks -verbose
report_clock_networks -file top_amc502_xaui_clocks.log
report_clock_interaction -append -file top_amc502_xaui_clocks.log
report_cdc -summary -append -file top_amc502_xaui_clocks.log
report_methodology -file top_amc502_xaui_methodology.log -cells [get_cells {xaui_imp/*}]

link_design -top top_amc502_xaui -part xc7k420tffg1156-2

create_debug_core u_ila_0 ila
set_property C_DATA_DEPTH 2048 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets clk200mhz_out]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]

set debug_nets { {amc502_imp/tclkb_imp/r_frame[*]} \
                 {amc502_imp/tclka_imp/latch_buffer[*]} \
                 {amc502_imp/tclk_data_valid} \
                 {amc502_imp/tclk_data[*]} \
                 {amc502_imp/tclka_strobe[*]} \
                 {amc502_imp/count_imp/enable[*]} \
                 {amc502_imp/count_imp/counter_array[14][*]} \
                 {amc502_imp/count_imp/rst} \
               }
set n 0
foreach debug_net $debug_nets {
  set n [expr $n + [llength [get_nets [list $debug_net]]]]
  puts "Debugging net $debug_net"
}
puts "Found a total of $n debug nets."
set_property port_width $n [get_debug_ports u_ila_0/probe0]
foreach debug_net $debug_nets {
  puts "Connecting debug net $debug_net"
  connect_debug_port u_ila_0/probe0 [lsort -dictionary [get_nets [list $debug_net]]]
  report_property [lindex [get_nets [list $debug_net]] 0]
}

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk200mhz_out]

opt_design -debug_log
report_clock_networks -append -file top_amc502_xaui_clocks.log
report_clock_interaction -append -file top_amc502_xaui_clocks.log
report_cdc -summary -append -file top_amc502_xaui_clocks.log

implement_debug_core [get_debug_cores u_ila_0]
write_debug_probes -force top_amc502_xaui.ltx

place_design
route_design
report_route_status
check_timing -file top_amc502_xaui_timing.log
report_timing_summary -verbose -append -file top_amc502_xaui_timing.log

get_clocks -include_generated_clocks { amc502_fpclka_p amc502_fpclkb_p amc502_fpclkc_p amc502_fpclkd_p }

write_checkpoint -force -noxdef top_amc502_xaui_impl.dcp

add_files -norecurse ./workspace/monitor_amc502_xaui.elf
set_property SCOPED_TO_REF microblaze_mcs_0 [get_files ./workspace/monitor_amc502_xaui.elf]
set_property SCOPED_TO_CELLS { U0/microblaze_I } [get_files ./workspace/monitor_amc502_xaui.elf]

write_bitstream -force "amc502_xaui.bit"

exit
