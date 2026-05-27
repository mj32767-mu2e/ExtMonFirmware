----------------------------------------------------------------------------------
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    13:03:10 06/09/2016 
-- Design Name:    amc502
-- Package Name:   gbe
-- Project Name:   amc502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Defines a dual-port RAM filled by UDP packets.
--
-- Dependencies:
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity xaui_udpbuffer is
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
    clkb : in std_logic;
    enb : in std_logic;
    addrb : in std_logic_vector(8 downto 0);
    doutb : out std_logic_vector(31 downto 0)
  );
end xaui_udpbuffer;

architecture RTL of xaui_udpbuffer is
  type ram_type is array(511 downto 0) of std_logic_vector(31 downto 0);
  signal ram : ram_type;
  signal write_address : integer range 0 to 255 := 0;
  signal source_ip_addr : std_logic_vector(31 downto 0);
  signal dest_ip_addr : std_logic_vector(31 downto 0);
  signal source_port : std_logic_vector(15 downto 0);
  signal dest_port : std_logic_vector(15 downto 0);
  signal udp_length : std_logic_vector(15 downto 0);
  signal latched_udp : std_logic := '0';
begin

  process ( clka )
    variable word : integer range 0 to 511;
    variable byte : integer range 0 to 3;
  begin

    if ( clka'event and clka = '1' ) then
      if ( reset = '1' ) then
        write_address <= 0;
        latched_udp <= '0';
      elsif ( wea = '1' ) then
        if ( latched_udp = '0' ) then
          latched_udp <= '1';
          source_ip_addr <= saddr;
          dest_ip_addr <= daddr;
          source_port <= sport;
          dest_port <= dport;
          udp_length <= length;
        end if;
--
--  write_address counts 32-bit words
--
        word := write_address;
        ram(word) <= rxd(31 downto 0);
        ram(word+1) <= rxd(63 downto 32);
        write_address <= write_address + 2;
      end if;
    end if;
  end process;

  process ( clkb ) begin
    if ( clkb'event and clkb = '1' ) then
      if ( enb = '1' ) then
        case addrb is
          when "111111100" =>
            doutb <= source_ip_addr;  -- x"7ff0"
          when "111111101" =>
            doutb <= dest_ip_addr;  -- x"7ff0"
          when "111111110" =>
            doutb <= source_port & dest_port;   -- x"7ff8"
          when "111111111" =>
            doutb <= udp_length & std_logic_vector(to_unsigned(write_address,16));      -- x"7ffc"
          when others =>
            doutb <= ram(to_integer(unsigned(addrb)));
        end case;
      end if;
    end if;
  end process;

end RTL;
