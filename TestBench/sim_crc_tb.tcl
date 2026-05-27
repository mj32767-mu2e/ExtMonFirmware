create_project -in_memory -part xc7k420tffg1156-2
set_property target_simulator "XSim" [current_project]
set_property parent.project_path ./sim_crc_tb.xpr [current_project]
set_property target_language VHDL [current_project]
read_vhdl -library hep337dev -verbose { \
  ../Sources/validation.vhd \
  ../Sources/utilities.vhd \
  ../Sources/crc32x64.vhd \
  ../Sources/crc8x32_const.vhd \
  ../Sources/crc8x32_table.vhd \
  ../Sources/crc32x64rom.vhd \
  ../Sources/crc32x64_table.vhd \
  ../Sources/crc32x64_slice.vhd \
}
read_vhdl ./sim_crc_tb.vhd
save_project_as -force sim_crc_tb
# synth_design -top sim_crc_tb
set_property top sim_crc_tb [get_filesets sim_1]
launch_simulation -mode behavioral
