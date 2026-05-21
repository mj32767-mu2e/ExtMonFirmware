set_part xc7k420tffg1156-2
create_project -in_memory -part xc7k420tffg1156-2
set_property parent.project_path ./amc502.xpr [current_project]
set_property target_language VHDL [current_project]
set_property ip_output_repo ./ip [current_project]
set_property ip_cache_permissions {read write} [current_project]

read_ip ./ip/microblaze_mcs_0.xci
export_ip_user_files -of_objects  [get_files ./ip/microblaze_mcs_0.xci] -sync -no_script -force -quiet
generate_target all [get_files ./ip/microblaze_mcs_0.xci]

read_vhdl ./sources/top_amc502.vhd
read_ip ./ip/microblaze_mcs_0.xci
read_xdc ./constrs/pins_amc502.xdc
read_xdc ./constrs/timing_amc502.xdc

synth_ip [get_ips microblaze_mcs_0]
synth_design -top top_amc502 -part xc7k420tffg1156-2
write_checkpoint -force -noxdef top_amc502_synth.dcp

add_files top_amc502.dcp
link_design -top top_amc502 -part xc7k420tffg1156-2
opt_design
place_design
route_design

write_checkpoint -force -noxdef top_amc502_impl.dcp

add_files -norecurse ./workspace/monitor_amc502.elf
set_property SCOPED_TO_REF microblaze_mcs_0 [get_files ./workspace/monitor_amc502.elf]
set_property SCOPED_TO_CELLS { U0/microblaze_I } [get_files ./workspace/monitor_amc502.elf]

write_bitstream -force "amc502.bit"

exit
