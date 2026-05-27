----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/11/2018 4:38:07 pm
-- Design Name: 
-- Module Name: iobus_interface - Behavioral
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
--  Copied and cleaned up from ages past.
--
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hep337dev;
use hep337dev.iobus.all;

entity iobus_interface is
  generic (
    nslave : integer := 1
  );
  port (
    clk : in std_logic;
    master : in iobus_t;
    second_master : in iobus_t;
    io_read_data : out std_logic_vector(31 downto 0);
    io_ready : out std_logic;
    slave : out iobus_array_t(nslave-1 downto 0);
    io_write_data : in data_array_t(nslave-1 downto 0);
    slave_ready : in ready_array_t(nslave-1 downto 0)
  );
end iobus_interface;

architecture behavioral of iobus_interface is
  signal ready : std_logic;
  signal not_ready : std_logic;
  signal next_ready : std_logic;
begin

  g: for i in 0 to nslave-1 generate
    slave(i).io_addr_strobe <= master.io_addr_strobe;
    slave(i).io_read_strobe <= master.io_read_strobe;
    slave(i).io_write_strobe <= master.io_write_strobe;
    slave(i).io_address <= master.io_address;
    slave(i).io_byte_enable <= master.io_byte_enable;
    slave(i).io_write_data <= master.io_write_data;
  end generate;

  process ( clk ) begin
    if ( clk'event and clk = '0' ) then
      next_ready <= master.io_addr_strobe;
    end if;
  end process;

  process ( clk ) begin
    if ( clk'event and clk = '1' ) then
      not_ready <= next_ready;
    end if;
  end process;

  process ( slave_ready, io_write_data, not_ready )
    variable ready : std_logic;
    variable data : std_logic_vector(31 downto 0);
  begin
    ready := not_ready;
    data := x"f8f8f8f8";
    for i in 0 to nslave-1 loop
      if ( slave_ready(i) = '1' ) then
        ready := '1';
        data := io_write_data(i);
        exit;
      end if;
    end loop;
    io_ready <= ready;
    io_read_data <= data;
  end process;

end behavioral;
