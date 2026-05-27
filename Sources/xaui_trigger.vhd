----------------------------------------------------------------------------------
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    03:39:10 01/03/0219 
-- Design Name:    amc502
-- Package Name:   xaui_trigger
-- Project Name:   amc502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    receives trigger packets over the xaui interface
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

entity xaui_trigger is
  port (
    reset : in std_logic;
    clka : in std_logic;
    wea : in std_logic;
    rxd : in std_logic_vector(63 downto 0);
    rxc : in std_logic_vector(7 downto 0);
    saddr : in std_logic_vector(31 downto 0);
    daddr : in std_logic_vector(31 downto 0);
    sport : in std_logic_vector(15 downto 0);
    dport : in std_logic_vector(15 downto 0);
    length : in std_logic_vector(15 downto 0);
    trigger_we : out std_logic
  );
end xaui_trigger;

architecture RTL of xaui_trigger is
  signal source_ip_addr : std_logic_vector(31 downto 0);
  signal dest_ip_addr : std_logic_vector(31 downto 0);
  signal source_port : std_logic_vector(15 downto 0);
  signal dest_port : std_logic_vector(15 downto 0);
  signal udp_length : std_logic_vector(15 downto 0);
  signal latched_udp : std_logic := '0';
begin

  process ( clka ) begin

    if ( clka'event and clka = '1' ) then
      if ( reset = '1' ) then
        latched_udp <= '0';
      elsif ( wea = '1' ) then
        if ( latched_udp = '0' ) then
          latched_udp <= '1';
          source_ip_addr <= saddr;
          dest_ip_addr <= daddr;
          source_port <= sport;
          dest_port <= dport;
          udp_length <= length;
        else
          udp_length <= std_logic_vector(unsigned(udp_length)-8);
        end if;
      else
        latched_udp <= '0';
      end if;
    end if;
  end process;
  trigger_we <= wea when udp_length /= "0000" else '0';

end RTL;
