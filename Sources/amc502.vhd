----------------------------------------------------------------------------------
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    10:52:39 06/14/2016 
-- Design Name:    amc502
-- Package Name:   amc502
-- Project Name:   AMC502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Interface for VadaTech AMC502 board components
--
-- Dependencies:
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

library hep337dev;
use hep337dev.iobus.all;

package amc502 is

  component amc502_interface is
    generic (
      nclock : integer := 8
    );
    port (
      clk100mhz : in std_logic;
      clk200mhz : in std_logic;
      clk20mhz : in std_logic;
      clk10mhz : out std_logic;
      scl_l1 : out std_logic;
      sda_l1_out : out std_logic;
      sda_l1_in : in std_logic;
      sda_l1_t : out std_logic;
      scl_lllx : in std_logic;
      sda_lllx_out : out std_logic;
      sda_lllx_in : in std_logic;
      sda_lllx_t : out std_logic;
      io_address_strobe : out std_logic;
      io_read_strobe : out std_logic;
      io_write_strobe : out std_logic;
      io_address : out std_logic_vector(31 downto 0);
      io_write_data : out std_logic_vector(31 downto 0);
      io_read_data : in std_logic_vector(31 downto 0);
      pll_rst_n : out std_logic;
      tdaq_sysclk : in std_logic;
      flag_event_marker : in std_logic;
      flag_clk40mhz_marker : in std_logic;
      event_marker : in std_logic_vector(47 downto 0);
      fpclka : in std_logic;
      fpclkb : in std_logic;
      tclka : in std_logic;
      tclkb : out std_logic;
      bcoclk : out std_logic;
      sysclk : out std_logic;
      sysclk2 : out std_logic;
      bco : out std_logic_vector(47 downto 0);
      fei4_lv1 : out std_logic;
      fpclk : in std_logic_vector(15 downto 0);
      cmd_strobe : out std_logic_vector(15 downto 0);
      stop_timer : in std_logic;
      uled : out std_logic_vector(3 downto 0);
      uled_select : out std_logic;

      busclk : in std_logic;
      onepps : out std_logic;
      iobus : in iobus_t;
      write_data : out std_logic_vector(31 downto 0);
      iobus_ready : out std_logic
    ); 
  end component;

end package amc502;
