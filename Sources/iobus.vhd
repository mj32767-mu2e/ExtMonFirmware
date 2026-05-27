----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/11/2018 4:37:07 PM
-- Design Name: 
-- Module Name: iobus - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.00 - File Created
--
-- Additional Comments:
--
--   Copied and cleaned up from ages past...
--   
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package iobus is

  type iobus_t is record
      io_addr_strobe : std_logic;
      io_read_strobe : std_logic;
      io_write_strobe : std_logic;
      io_address : std_logic_vector(31 downto 0);
      io_byte_enable : std_logic_vector(3 downto 0);
      io_write_data : std_logic_vector(31 downto 0);
  end record;
  type iobus_array_t is array(integer range <>) of iobus_t;
  type data_array_t is array(integer range <>) of std_logic_vector(31 downto 0);
  type ready_array_t is array(integer range <>) of std_logic;

  component iobus_interface is
    generic (
      nslave : integer := 1
    );
    port (
      clk : in std_logic;
      master : in iobus_t;
      second_master : in iobus_t;
      io_read_data : out std_logic_vector(31 downto 0);
      io_ready : out std_logic;
      slave : out iobus_array_t;
      io_write_data : in data_array_t;
      slave_ready : in ready_array_t
    );
  end component;

end package iobus;
