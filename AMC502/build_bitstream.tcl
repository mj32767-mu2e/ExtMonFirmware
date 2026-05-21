set_part xc7k420tffg1156-2
create_project -in_memory -part xc7k420tffg1156-2
set_property parent.project_path ./amc502.xpr [current_project]
set_property target_language VHDL [current_project]
set_property ip_output_repo ./ip [current_project]
set_property ip_cache_permissions {read write} [current_project]

add_files top_amc502_impl.dcp
add_files -norecurse ./workspace/monitor_amc502.elf
set_property SCOPED_TO_REF microblaze_mcs_0 [get_files ./workspace/monitor_amc502.elf]
set_property SCOPED_TO_CELLS { U0/microblaze_I } [get_files ./workspace/monitor_amc502.elf]

write_bitstream -force "amc502.bit"

exit
