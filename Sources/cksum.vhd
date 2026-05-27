--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    09:59:57 06/13/2016 
-- Design Name:    amc502
-- Module Name:    cksum - RTL
-- Project Name:   AMC502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Computes 16-bit one's compliment checksum
--
-- Dependencies:   add8
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity cksum is
  port ( din : in  std_logic_vector (7 downto 0);
         clk : in  std_logic;
         enable : in  std_logic;
         checksum : out  std_logic_vector (15 downto 0)
       );
end cksum;

architecture RTL of cksum is

  signal sum : std_logic_vector(15 downto 0);
  
  signal enable_high : std_logic;
  signal enable_low : std_logic;
  signal carry_low : std_logic;
  signal carry_high : std_logic;
  signal clear : std_logic;
  
  component add8
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
  end component;

begin

  sum_low : add8
  port map (
    a => din,
    b => sum(7 downto 0),
    s => sum(7 downto 0),
    clk => clk,
    ce => enable_low,
    sclr => clear,
    c_out => carry_low,
    c_in => carry_high
  );
  sum_high : add8
  port map (
    a => din,
    b => sum(15 downto 8),
    s => sum(15 downto 8),
    clk => clk,
    ce => enable_high,
    sclr => clear,
    c_out => carry_high,
    c_in => carry_low
  );

  process ( clk, enable ) begin
    if ( clk'event and clk = '1' ) then
      if ( enable = '0' ) then
        enable_high <= '1';
      else
        enable_high <= not enable_high;
      end if;
    end if;
  end process;
  clear <= not enable;
  enable_low <= not enable_high;
  checksum <= not sum;

end RTL;
