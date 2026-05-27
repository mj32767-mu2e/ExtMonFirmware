----------------------------------------------------------------------------------
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    12/31/2018
-- Design Name:    mu2e_amc502
-- Package Name:   utilities 
-- Project Name:   Mu2e
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    This defines some useful functions
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

package utilities is

  function log2( input : integer ) return integer;
  function byte_reorder( input : std_logic_vector(31 downto 0) )
    return std_logic_vector;

end package utilities;

package body utilities is

  function log2( input : integer ) return integer is
    variable temp, log : integer;
  begin
    temp := input/2;
    log := 0;
    while ( temp /= 0 ) loop
      temp := temp/2;
      log := log + 1;
    end loop;
    return log;
  end function log2;

  function byte_reorder( input : std_logic_vector(31 downto 0) )
    return std_logic_vector is
    variable temp : std_logic_vector(31 downto 0);
  begin
    temp(7 downto 0) := input(31 downto 24);
    temp(15 downto 8) := input(23 downto 16);
    temp(23 downto 16) := input(15 downto 8);
    temp(31 downto 24) := input(7 downto 0);
    return temp;
  end function byte_reorder;

end utilities;

