----------------------------------------------------------------------------------
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    08/31/2021 
-- Design Name:    mu2e_amc502
-- Package Name:   test
-- Project Name:   Mu2e
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.2
-- Description:    This defines the interface for various internal tests 
--
-- Dependencies:
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hep337dev;
use hep337dev.iobus.all;

package test is

  component test_interface is
    port (
      busclk : in std_logic;
      iobus : in iobus_t;
      write_data : out std_logic_vector(31 downto 0);
      iobus_ready : out std_logic;
      bco : in std_logic_vector(47 downto 0);
      xaui_stream_clk : in std_logic;
      xaui_stream_wren : out std_logic;
      xaui_stream_strobe : out std_logic;
      xaui_stream_dout : out std_logic_vector(63 downto 0);
      xaui_stream_free : in std_logic_vector(15 downto 0);
      buffer_status : out std_logic_vector(31 downto 0);
      buffer_reset : in std_logic_vector(31 downto 0)
    ); 
  end component;

end package test;
