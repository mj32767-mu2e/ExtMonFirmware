----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/03/2016 07:20:02 PM
-- Design Name: 
-- Module Name: crc32x64_table - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description:   Calculates the 32-bit IEEE 802.3 FCS with 64-bit input word
--                based on 256x32 bit ROM lookup tables and other stuff.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity crc32x64_table is
port (
  clk : in std_logic;
  en : in std_logic;
  clr : in std_logic;
  din : in std_logic_vector(63 downto 0);
  cin : in std_logic_vector(7 downto 0);
  dout : out std_logic_vector(31 downto 0);
  valid : out std_logic
);
end crc32x64_table;

architecture Behavioral of crc32x64_table is

  function flip(d: std_logic_vector) return std_logic_vector is
    variable q: std_logic_vector(d'reverse_range);
  begin
    for i in d'range loop
      q(i) := d(i);
    end loop;
    return q;
  end flip;

  component crc8x32_table
  port (
    crc : in std_logic_vector(31 downto 0);
    a : in std_logic_vector(7 downto 0);
    c : in std_logic;
    spo : out std_logic_vector(31 downto 0)
  );
  end component;

  signal s : std_logic_vector(31 downto 0) := ( others => '1' );
--  constant residue : std_logic_vector(31 downto 0) := x"c704dd7b";
  constant residue : std_logic_vector(31 downto 0) := x"debb20e3";
  type q_t is array(0 to 8) of std_logic_vector(31 downto 0);
  signal q : q_t;

--  attribute mark_debug : string;
--  attribute mark_debug of s : signal is "true";

begin

  g_rom : for i in 0 to 7 generate
    rom_imp : crc8x32_table
    port map (
      crc => q(i),
      a => din(7+8*i downto 8*i),
      c => cin(i),
      spo => q(i+1)
    );
  end generate;

  q(0) <= s;

  process ( clk )
    variable p : std_logic_vector(31 downto 0);
    variable c : std_logic_vector(31 downto 0);
    variable d : std_logic_vector(7 downto 0);
  begin
    if ( clk'event and clk = '1' ) then
      if ( clr = '1' ) then
        s <= ( others => '1' );
        valid <= '0';
      elsif ( en = '1' ) then
        s <= q(8);
        dout <= not q(8);
      else
        valid <= '0';
      end if;
      if ( q(8) = residue ) then
        valid <= '1';
        s <= ( others => '1' );
      else
        valid <= '0';
      end if;
    end if;
  end process;

end Behavioral;
