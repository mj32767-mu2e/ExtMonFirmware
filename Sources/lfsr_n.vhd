----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/21/2016 09:26:13 AM
-- Design Name: 
-- Module Name: grey_counter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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
use ieee.numeric_std.all;

entity lfsr_n is
generic (
  width : natural := 4
);
port (
  rst : in std_logic;
  clk : in std_logic;
  en : in std_logic;
  dout : out std_logic_vector(width-1 downto 0);
  prev : out std_logic_vector(width-1 downto 0)
);
end lfsr_n;

architecture Behavioral of lfsr_n is

  signal q : std_logic_vector(width-1 downto 0) := ( 0 => '1', others => '0' );
  signal poly : std_logic_vector(width-1 downto 0) := ( others => '0' );

begin

  assert ( ( width >= 4 and width <= 31 ) or width = 64 )
    report "lfsr_n : requested width not implemented."
      severity FAILURE;
  g64 : if ( width = 64 ) generate
    poly <= "1101100000000000000000000000000000000000000000000000000000000000";
  end generate;
  g31 : if ( width = 31 ) generate
    poly <= "1001000000000000000000000000000";
  end generate;
  g30 : if ( width = 30 ) generate
    poly <= "100000000000000000000000101001";
  end generate;
  g29 : if ( width = 29 ) generate
    poly <= "10100000000000000000000000000";
  end generate;
  g28 : if ( width = 28 ) generate
    poly <= "1001000000000000000000000000";
  end generate;
  g27 : if ( width = 27 ) generate
    poly <= "100000000000000000000010011";
  end generate;
  g26 : if ( width = 26 ) generate
    poly <= "10000000000000000000100011";
  end generate;
  g25 : if ( width = 25 ) generate
    poly <= "1001000000000000000000000";
  end generate;
  g24 : if ( width = 24 ) generate
    poly <= "111000010000000000000000";
  end generate;
  g23 : if ( width = 23 ) generate
    poly <= "10000100000000000000000";
  end generate;
  g22 : if ( width = 22 ) generate
    poly <= "1100000000000000000000";
  end generate;
  g21 : if ( width = 21 ) generate
    poly <= "101000000000000000000";
  end generate;
  g20 : if ( width = 20 ) generate
    poly <= "10010000000000000000";
  end generate;
  g19 : if ( width = 19 ) generate
    poly <= "1110010000000000000";
  end generate;
  g18 : if ( width = 18 ) generate
    poly <= "100000010000000000";
  end generate;
  g17 : if ( width = 17 ) generate
    poly <= "10010000000000000";
  end generate;
  g16 : if ( width = 16 ) generate
--    poly <= "1011010000000000";
    poly <= "1101000000001000";
  end generate;
  g15 : if ( width = 15 ) generate
    poly <= "110000000000000";
  end generate;
  g14 : if ( width = 14 ) generate
--    poly <= "10000000010101";
    poly <= "11100000000010";
  end generate;
  g13 : if ( width = 13 ) generate
--    poly <= "1000000001101";
    poly <= "1110010000000";
  end generate;
  g12 : if ( width = 12 ) generate
--    poly <= "100000101001";
    poly <= "100110010000";
  end generate;
  g11 : if ( width = 11 ) generate
    poly <= "10100000000";
  end generate;
  g10 : if ( width = 10 ) generate
    poly <= "1001000000";
  end generate;
  g9 : if ( width = 9 ) generate
    poly <= "100010000";
  end generate;
  g8 : if ( width = 8 ) generate
    poly <= "10111000";
  end generate;
  g7 : if ( width = 7 ) generate
    poly <=  "1100000";
  end generate;
  g6 : if ( width = 6 ) generate
    poly <=  "110000";
  end generate;
  g5 : if ( width = 5 ) generate
    poly <=  "10100";
  end generate;
  g4 : if ( width = 4 ) generate
    poly <= "1100";
  end generate;

  process ( rst, clk )
    variable lsb : std_logic;
    variable ext : std_logic_vector(width-1 downto 0);
  begin
    if ( clk'event and clk = '1' ) then
      if ( rst = '1' ) then
        q <= ( 0 => '1', others => '0' );
        prev <= ( 1 => '1', others => '0' );
      elsif ( en = '1' ) then
        prev <= q;
        lsb := q(0);
        for i in 0 to width-1 loop
          ext(i) := lsb;
        end loop;
        q <= ( '0' & q(width-1 downto 1) ) xor ( ext and poly );
      end if;
    end if;
  end process;
  dout <= q;

end Behavioral;
