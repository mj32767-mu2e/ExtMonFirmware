--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    20:32:20 06/10/2016 
-- Design Name:    amc502
-- Module Name:    amc502 gbe - RTL
-- Project Name:   amc502 firmware
-- Target Devices: xc5k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Add two bytes with carry
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity add8 is
  port (  
    a : in std_logic_vector(7 downto 0);
    b : in std_logic_vector(7 downto 0);
    clk : in std_logic;
    c_in : in std_logic;
    ce : in std_logic;
    sclr : in std_logic;
    c_out : out std_logic;
    s : out std_logic_vector(7 downto 0)
  );
end add8;

architecture RTL of add8 is

  signal sumab : unsigned(8 downto 0);

begin

  process ( clk ) begin
    if ( clk'event and clk = '1' ) then
      if ( sclr = '1' ) then
        sumab <= ( others => '0' );
      elsif ( ce = '1' ) then
        if ( c_in = '0' ) then
          sumab <= unsigned("0" & a) + unsigned("0" & b);
        else
          sumab <= unsigned("0" & a) + unsigned("0" & b) + "1";
        end if;  
      end if;
    end if;
  end process;

  s <= std_logic_vector(sumab(7 downto 0));
  c_out <= std_logic(sumab(8));

end RTL;
