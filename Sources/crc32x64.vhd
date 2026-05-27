----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/03/2016 07:20:02 PM
-- Design Name: 
-- Module Name: crc32x64 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description:   Calculates the 32-bit IEEE 802.3 FCS with 64-bit input word
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

entity crc32x64 is
port (
  clk : in std_logic;
  en : in std_logic;
  clr : in std_logic;
  din : in std_logic_vector(63 downto 0);
  cin : in std_logic_vector(7 downto 0);
  dout : out std_logic_vector(31 downto 0);
  valid : out std_logic
);
end crc32x64;

architecture Behavioral of crc32x64 is

  function flip(d: std_logic_vector) return std_logic_vector is
    variable q: std_logic_vector(d'reverse_range);
  begin
    for i in d'range loop
      q(i) := d(i);
    end loop;
    return q;
  end flip;

  signal s : std_logic_vector(31 downto 0) := ( others => '1' );
  constant residue : std_logic_vector(31 downto 0) := x"c704dd7b";

begin

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
        c := s;
        for i in 0 to 7 loop
          if ( cin(i) = '0' ) then
            d := flip(din(7+8*i downto 8*i));
            p(0) := d(6) xor d(0) xor c(24) xor c(30);
            p(1) := d(7) xor d(6) xor d(1) xor d(0) xor c(24) xor c(25) xor c(30) xor c(31);
            p(2) := d(7) xor d(6) xor d(2) xor d(1) xor d(0) xor c(24) xor c(25) xor c(26) xor c(30) xor c(31);
            p(3) := d(7) xor d(3) xor d(2) xor d(1) xor c(25) xor c(26) xor c(27) xor c(31);
            p(4) := d(6) xor d(4) xor d(3) xor d(2) xor d(0) xor c(24) xor c(26) xor c(27) xor c(28) xor c(30);
            p(5) := d(7) xor d(6) xor d(5) xor d(4) xor d(3) xor d(1) xor d(0) xor c(24) xor c(25) xor c(27) xor c(28) xor c(29) xor c(30) xor c(31);
            p(6) := d(7) xor d(6) xor d(5) xor d(4) xor d(2) xor d(1) xor c(25) xor c(26) xor c(28) xor c(29) xor c(30) xor c(31);
            p(7) := d(7) xor d(5) xor d(3) xor d(2) xor d(0) xor c(24) xor c(26) xor c(27) xor c(29) xor c(31);
            p(8) := d(4) xor d(3) xor d(1) xor d(0) xor c(0) xor c(24) xor c(25) xor c(27) xor c(28);
            p(9) := d(5) xor d(4) xor d(2) xor d(1) xor c(1) xor c(25) xor c(26) xor c(28) xor c(29);
            p(10) := d(5) xor d(3) xor d(2) xor d(0) xor c(2) xor c(24) xor c(26) xor c(27) xor c(29);
            p(11) := d(4) xor d(3) xor d(1) xor d(0) xor c(3) xor c(24) xor c(25) xor c(27) xor c(28);
            p(12) := d(6) xor d(5) xor d(4) xor d(2) xor d(1) xor d(0) xor c(4) xor c(24) xor c(25) xor c(26) xor c(28) xor c(29) xor c(30);
            p(13) := d(7) xor d(6) xor d(5) xor d(3) xor d(2) xor d(1) xor c(5) xor c(25) xor c(26) xor c(27) xor c(29) xor c(30) xor c(31);
            p(14) := d(7) xor d(6) xor d(4) xor d(3) xor d(2) xor c(6) xor c(26) xor c(27) xor c(28) xor c(30) xor c(31);
            p(15) := d(7) xor d(5) xor d(4) xor d(3) xor c(7) xor c(27) xor c(28) xor c(29) xor c(31);
            p(16) := d(5) xor d(4) xor d(0) xor c(8) xor c(24) xor c(28) xor c(29);
            p(17) := d(6) xor d(5) xor d(1) xor c(9) xor c(25) xor c(29) xor c(30);
            p(18) := d(7) xor d(6) xor d(2) xor c(10) xor c(26) xor c(30) xor c(31);
            p(19) := d(7) xor d(3) xor c(11) xor c(27) xor c(31);
            p(20) := d(4) xor c(12) xor c(28);
            p(21) := d(5) xor c(13) xor c(29);
            p(22) := d(0) xor c(14) xor c(24);
            p(23) := d(6) xor d(1) xor d(0) xor c(15) xor c(24) xor c(25) xor c(30);
            p(24) := d(7) xor d(2) xor d(1) xor c(16) xor c(25) xor c(26) xor c(31);
            p(25) := d(3) xor d(2) xor c(17) xor c(26) xor c(27);
            p(26) := d(6) xor d(4) xor d(3) xor d(0) xor c(18) xor c(24) xor c(27) xor c(28) xor c(30);
            p(27) := d(7) xor d(5) xor d(4) xor d(1) xor c(19) xor c(25) xor c(28) xor c(29) xor c(31);
            p(28) := d(6) xor d(5) xor d(2) xor c(20) xor c(26) xor c(29) xor c(30);
            p(29) := d(7) xor d(6) xor d(3) xor c(21) xor c(27) xor c(30) xor c(31);
            p(30) := d(7) xor d(4) xor c(22) xor c(28) xor c(31);
            p(31) := d(5) xor c(23) xor c(29);
            c := p;
          end if;
        end loop;
        s <= p;
        dout <= not flip(p);
      else
        valid <= '0';
      end if;
      if ( s = residue ) then
        valid <= '1';
        s <= ( others => '1' );
      else
        valid <= '0';
      end if;
    end if;
  end process;

end Behavioral;
