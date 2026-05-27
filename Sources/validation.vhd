----------------------------------------------------------------------------------
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    12/31/2018
-- Design Name:    mu2e_amc502
-- Package Name:   validation
-- Project Name:   Mu2e
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    This defines some useful functions for simulation validation
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

package validation is

  function byte_to_string( v : std_logic_vector(7 downto 0) ) return string;
  function short_to_string( v : std_logic_vector(15 downto 0) ) return string;
  function long_to_string( v : std_logic_vector(31 downto 0) ) return string;
  function dlong_to_string( v : std_logic_vector(63 downto 0) ) return string;
  function parse_hex_character( c : character ) return std_logic_vector;
  function parse_hex_byte( s : string ) return std_logic_vector;
  function parse_hex_short( s : string ) return std_logic_vector;
  function parse_hex_long( s : string ) return std_logic_vector;
  function parse_hex_dlong( s : string ) return std_logic_vector;

end package validation;

package body validation is

  function byte_to_string( v : std_logic_vector(7 downto 0) ) return string is
    variable s : string(1 to 2);
  begin
    for i in 1 downto 0 loop
      case v(4*i+3 downto 4*i) is
      when "0000" =>
        s(2-i) := '0';
      when "0001" =>
        s(2-i) := '1';
      when "0010" =>
        s(2-i) := '2';
      when "0011" =>
        s(2-i) := '3';
      when "0100" =>
        s(2-i) := '4';
      when "0101" =>
        s(2-i) := '5';
      when "0110" =>
        s(2-i) := '6';
      when "0111" =>
        s(2-i) := '7';
      when "1000" =>
        s(2-i) := '8';
      when "1001" =>
        s(2-i) := '9';
      when "1010" =>
        s(2-i) := 'a';
      when "1011" =>
        s(2-i) := 'b';
      when "1100" =>
        s(2-i) := 'c';
      when "1101" =>
        s(2-i) := 'd';
      when "1110" =>
        s(2-i) := 'e';
      when "1111" =>
        s(2-i) := 'f';
      end case;
    end loop;
    return "0x" & s;
  end byte_to_string;

  function short_to_string( v : std_logic_vector(15 downto 0) ) return string is
    variable s : string(1 to 4);
  begin
    for i in 3 downto 0 loop
      case v(4*i+3 downto 4*i) is
      when "0000" =>
        s(4-i) := '0';
      when "0001" =>
        s(4-i) := '1';
      when "0010" =>
        s(4-i) := '2';
      when "0011" =>
        s(4-i) := '3';
      when "0100" =>
        s(4-i) := '4';
      when "0101" =>
        s(4-i) := '5';
      when "0110" =>
        s(4-i) := '6';
      when "0111" =>
        s(4-i) := '7';
      when "1000" =>
        s(4-i) := '8';
      when "1001" =>
        s(4-i) := '9';
      when "1010" =>
        s(4-i) := 'a';
      when "1011" =>
        s(4-i) := 'b';
      when "1100" =>
        s(4-i) := 'c';
      when "1101" =>
        s(4-i) := 'd';
      when "1110" =>
        s(4-i) := 'e';
      when "1111" =>
        s(4-i) := 'f';
      end case;
    end loop;
    return "0x" & s;
  end short_to_string;

  function long_to_string( v : std_logic_vector(31 downto 0) ) return string is
    variable s : string(1 to 8);
  begin
    for i in 7 downto 0 loop
      case v(4*i+3 downto 4*i) is
      when "0000" =>
        s(8-i) := '0';
      when "0001" =>
        s(8-i) := '1';
      when "0010" =>
        s(8-i) := '2';
      when "0011" =>
        s(8-i) := '3';
      when "0100" =>
        s(8-i) := '4';
      when "0101" =>
        s(8-i) := '5';
      when "0110" =>
        s(8-i) := '6';
      when "0111" =>
        s(8-i) := '7';
      when "1000" =>
        s(8-i) := '8';
      when "1001" =>
        s(8-i) := '9';
      when "1010" =>
        s(8-i) := 'a';
      when "1011" =>
        s(8-i) := 'b';
      when "1100" =>
        s(8-i) := 'c';
      when "1101" =>
        s(8-i) := 'd';
      when "1110" =>
        s(8-i) := 'e';
      when "1111" =>
        s(8-i) := 'f';
      end case;
    end loop;
    return "0x" & s;
  end long_to_string;

  function dlong_to_string( v : std_logic_vector(63 downto 0) ) return string is
    variable s : string(1 to 16);
  begin
    for i in 15 downto 0 loop
      case v(4*i+3 downto 4*i) is
      when "0000" =>
        s(16-i) := '0';
      when "0001" =>
        s(16-i) := '1';
      when "0010" =>
        s(16-i) := '2';
      when "0011" =>
        s(16-i) := '3';
      when "0100" =>
        s(16-i) := '4';
      when "0101" =>
        s(16-i) := '5';
      when "0110" =>
        s(16-i) := '6';
      when "0111" =>
        s(16-i) := '7';
      when "1000" =>
        s(16-i) := '8';
      when "1001" =>
        s(16-i) := '9';
      when "1010" =>
        s(16-i) := 'a';
      when "1011" =>
        s(16-i) := 'b';
      when "1100" =>
        s(16-i) := 'c';
      when "1101" =>
        s(16-i) := 'd';
      when "1110" =>
        s(16-i) := 'e';
      when "1111" =>
        s(16-i) := 'f';
      end case;
    end loop;
    return "0x" & s;
  end dlong_to_string;

  function parse_hex_character( c : character ) return std_logic_vector is
    variable v : std_logic_vector(3 downto 0);
  begin
    case c is
      when '0' =>
        v := "0000";
      when '1' =>
        v := "0001";
      when '2' =>
        v := "0010";
      when '3' =>
        v := "0011";
      when '4' =>
        v := "0100";
      when '5' =>
        v := "0101";
      when '6' =>
        v := "0110";
      when '7' =>
        v := "0111";
      when '8' =>
        v := "1000";
      when '9' =>
        v := "1001";
      when 'a' =>
        v := "1010";
      when 'A' =>
        v := "1010";
      when 'b' =>
        v := "1011";
      when 'B' =>
        v := "1011";
      when 'c' =>
        v := "1100";
      when 'C' =>
        v := "1100";
      when 'd' =>
        v := "1101";
      when 'D' =>
        v := "1101";
      when 'e' =>
        v := "1110";
      when 'E' =>
        v := "1110";
      when 'f' =>
        v := "1111";
      when 'F' =>
        v := "1111";
      when others =>
        v := "0000";
    end case;
    return v;
  end parse_hex_character;

  function parse_hex_byte( s : string ) return std_logic_vector is
    variable d : std_logic_vector(7 downto 0);
  begin
    for i in 1 to 2 loop
      d((2-i)*4+3 downto (2-i)*4) := parse_hex_character(s(i));
    end loop;
    return d;
  end parse_hex_byte;

  function parse_hex_short( s : string ) return std_logic_vector is
    variable d : std_logic_vector(15 downto 0);
  begin
    for i in 1 to 4 loop
      d((4-i)*4+3 downto (4-i)*4) := parse_hex_character(s(i));
    end loop;
    return d;
  end parse_hex_short;

  function parse_hex_long( s : string ) return std_logic_vector is
    variable d : std_logic_vector(31 downto 0);
  begin
    for i in 1 to 8 loop
      d((8-i)*4+3 downto (8-i)*4) := parse_hex_character(s(i));
    end loop;
    return d;
  end parse_hex_long;

  function parse_hex_dlong( s : string ) return std_logic_vector is
    variable d : std_logic_vector(63 downto 0);
  begin
    for i in 1 to 16 loop
      d((16-i)*4+3 downto (16-i)*4) := parse_hex_character(s(i));
    end loop;
    return d;
  end parse_hex_dlong;

end validation;

