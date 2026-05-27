----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/03/2016 07:20:02 PM
-- Design Name: 
-- Module Name: crc32x64rom - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description:   Calculates the 32-bit IEEE 802.3 FCS with 64-bit input word
--                based on 256x32 bit ROM lookup tables.
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

entity crc32x64rom is
port (
  clk : in std_logic;
  en : in std_logic;
  clr : in std_logic;
  din : in std_logic_vector(63 downto 0);
  cin : in std_logic_vector(7 downto 0);
  dout : out std_logic_vector(31 downto 0);
  valid : out std_logic
);
end crc32x64rom;

architecture Behavioral of crc32x64rom is

  function flip(d: std_logic_vector) return std_logic_vector is
    variable q: std_logic_vector(d'reverse_range);
  begin
    for i in d'range loop
      q(i) := d(i);
    end loop;
    return q;
  end flip;

  component crc8x32_const
  port (
    a : in std_logic_vector(7 downto 0);
    spo : out std_logic_vector(31 downto 0)
  );
  end component;

  signal s : std_logic_vector(31 downto 0) := ( others => '1' );
  constant residue : std_logic_vector(31 downto 0) := x"c704dd7b";
  type q_t is array(0 to 7) of std_logic_vector(31 downto 0);
  signal q : q_t;

begin

  g_rom : for i in 0 to 7 generate
    rom_imp : crc8x32_const
    port map (
      a => din(7+8*i downto 8*i),
      spo => q(i)
    );
  end generate;

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
            p(0) := q(i)(0) xor c(24) xor c(30);
            p(1) := q(i)(1) xor c(24) xor c(25) xor c(30) xor c(31);
            p(2) := q(i)(2) xor c(24) xor c(25) xor c(26) xor c(30) xor c(31);
            p(3) := q(i)(3) xor c(25) xor c(26) xor c(27) xor c(31);
            p(4) := q(i)(4) xor c(24) xor c(26) xor c(27) xor c(28) xor c(30);
            p(5) := q(i)(5) xor c(24) xor c(25) xor c(27) xor c(28) xor c(29) xor c(30) xor c(31);
            p(6) := q(i)(6) xor c(25) xor c(26) xor c(28) xor c(29) xor c(30) xor c(31);
            p(7) := q(i)(7) xor c(24) xor c(26) xor c(27) xor c(29) xor c(31);
            p(8) := q(i)(8) xor c(0) xor c(24) xor c(25) xor c(27) xor c(28);
            p(9) := q(i)(9) xor c(1) xor c(25) xor c(26) xor c(28) xor c(29);
            p(10) := q(i)(10) xor c(2) xor c(24) xor c(26) xor c(27) xor c(29);
            p(11) := q(i)(11) xor c(3) xor c(24) xor c(25) xor c(27) xor c(28);
            p(12) := q(i)(12) xor c(4) xor c(24) xor c(25) xor c(26) xor c(28) xor c(29) xor c(30);
            p(13) := q(i)(13) xor c(5) xor c(25) xor c(26) xor c(27) xor c(29) xor c(30) xor c(31);
            p(14) := q(i)(14) xor c(6) xor c(26) xor c(27) xor c(28) xor c(30) xor c(31);
            p(15) := q(i)(15) xor c(7) xor c(27) xor c(28) xor c(29) xor c(31);
            p(16) := q(i)(16) xor c(8) xor c(24) xor c(28) xor c(29);
            p(17) := q(i)(17) xor c(9) xor c(25) xor c(29) xor c(30);
            p(18) := q(i)(18) xor c(10) xor c(26) xor c(30) xor c(31);
            p(19) := q(i)(19) xor c(11) xor c(27) xor c(31);
            p(20) := q(i)(20) xor c(12) xor c(28);
            p(21) := q(i)(21) xor c(13) xor c(29);
            p(22) := q(i)(22) xor c(14) xor c(24);
            p(23) := q(i)(23) xor c(15) xor c(24) xor c(25) xor c(30);
            p(24) := q(i)(24) xor c(16) xor c(25) xor c(26) xor c(31);
            p(25) := q(i)(25) xor c(17) xor c(26) xor c(27);
            p(26) := q(i)(26) xor c(18) xor c(24) xor c(27) xor c(28) xor c(30);
            p(27) := q(i)(27) xor c(19) xor c(25) xor c(28) xor c(29) xor c(31);
            p(28) := q(i)(28) xor c(20) xor c(26) xor c(29) xor c(30);
            p(29) := q(i)(29) xor c(21) xor c(27) xor c(30) xor c(31);
            p(30) := q(i)(30) xor c(22) xor c(28) xor c(31);
            p(31) := q(i)(31) xor c(23) xor c(29);
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
