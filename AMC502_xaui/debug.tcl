open_hw_manager
connect_hw_server -url localhost:3121 -allow_non_jtag
open_hw_target
set_property PROGRAM.FILE {./amc502_xaui.bit} [get_hw_devices xc7k420t_0]
current_hw_device [get_hw_devices xc7k420t_0]
# refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7k420t_0] 0]
set_property PROBES.FILE ./amc502_xaui_probes.ltx [get_hw_devices xc7k420t_0]
set_property FULL_PROBES.FILE ./amc502_xaui_probes.ltx [get_hw_devices xc7k420t_0]
# program_hw_devices [get_hw_devices xc7k420t_0]
refresh_hw_device [lindex get_hw_devices] 0]

run_hw_ila hw_ila_1
wait_on_hw_ila hw_ila_1
current_hw_ila_data [upload_hw_ila_data hw_ila_1]

exit
