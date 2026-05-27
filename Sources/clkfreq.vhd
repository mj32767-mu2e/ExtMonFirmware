--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    10:56:38 06/14/2016 
-- Design Name:    amc502
-- Module Name:    i2c - RTL
-- Project Name:   AMC502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    i2c bus interface
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

library unisim;
use unisim.vcomponents.all;
library unimacro;
use unimacro.vcomponents.all;

entity clkfreq is
  port (
    clk100mhz : in std_logic;
    onepps : in std_logic;
    clk : in std_logic;
    count : out std_logic_vector(31 downto 0)
  );
end clkfreq;

architecture RTL of clkfreq is

  signal count0 : signed(31 downto 0);
  signal count1 : std_logic_vector(31 downto 0);
  signal count2 : std_logic_vector(31 downto 0);
  signal diff : signed(31 downto 0);
begin

    count_imp : counter_tc_macro
    generic map (
      device => "7SERIES",
      direction => "UP",
      reset_upon_tc => "TRUE",
      width_data => 32
    )
    port map (
      clk => clk,
      ce => '1',
      q => count1,
      rst => '0',
      tc => open
    );
 
  count <= std_logic_vector(diff);

  process ( clk100mhz ) begin
    if ( clk100mhz'event and clk100mhz = '1' ) then
      count2 <= count1;
      if ( onepps = '1' ) then
        diff <= signed(count2) - count0;
        count0 <= signed(count2);
      end if;
    end if;
  end process;

end RTL;
