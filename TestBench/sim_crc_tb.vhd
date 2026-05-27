----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/15/2018 12:10:17 PM
-- Design Name: 
-- Module Name: sim_crc_tb.vhd - Behavioral
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
--   This test bench compares the result of the crc32x64 code which is based
--   on combinatorial logic, and the crc32x64rom code which uses 8x32 bit
--   lookup tables.
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library hep337dev;
-- use hep337dev.xaui.all;
use hep337dev.validation.all;

entity sim_crc_tb is
--  Port ( );
end sim_crc_tb;

architecture behavioral of sim_crc_tb is

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
      when 'b' =>
        v := "1011";
      when 'c' =>
        v := "1100";
      when 'd' =>
        v := "1101";
      when 'e' =>
        v := "1110";
      when 'f' =>
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

  component crc32x64
  port (
    clk : in std_logic;
    en : in std_logic;
    clr : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(31 downto 0);
    valid : out std_logic
  );
  end component;

  component crc32x64rom
  port (
    clk : in std_logic;
    en : in std_logic;
    clr : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(31 downto 0);
    valid : out std_logic
  );
  end component;

  component crc32x64_table
  port (
    clk : in std_logic;
    en : in std_logic;
    clr : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(31 downto 0);
    valid : out std_logic
  );
  end component;

  component crc32x64_slice
  port (
    clk : in std_logic;
    en : in std_logic;
    clr : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(31 downto 0);
    valid : out std_logic
  );
  end component;

  constant xgmii_clk_period : time := 6.4 ns;

  signal clk : std_logic;
  signal txd : std_logic_vector(63 downto 0);
  signal txc : std_logic_vector(7 downto 0);
  signal ctrl : std_logic_vector(7 downto 0);
  signal crc_en : std_logic := '1';
  signal crc_clr : std_logic := '0';
  signal crc : std_logic_vector(31 downto 0) := ( others => '0' );
  signal valid : std_logic;
  signal crc_rom : std_logic_vector(31 downto 0) := ( others => '0' );
  signal valid_rom : std_logic;
  signal crc_table : std_logic_vector(31 downto 0) := ( others => '0' );
  signal valid_table : std_logic;
  signal crc_slice : std_logic_vector(31 downto 0) := ( others => '0' );
  signal valid_slice : std_logic;

begin

  xgmii_clk_proc : process begin
    clk <= '0';
    wait for xgmii_clk_period/2;
    clk <= '1';
    wait for xgmii_clk_period/2;
  end process;

  stim_process : process ( clk )
    file infile : text open read_mode is "/tmp/crc_input.dat";
    variable input_line : line;
    variable c : character;
    variable sb : string(1 to 2);
    variable sc : string(1 to 2);
    variable sd : string(1 to 16);
  begin
    if ( clk'event and clk = '1' ) then
      if ( not endfile(infile) ) then
        readline(infile,input_line);
        read(input_line,sb);
        ctrl <= parse_hex_byte(sb);
        read(input_line,c);
        read(input_line,sc);
        txc <= parse_hex_byte(sc);
        read(input_line,c);
        read(input_line,sd);
        txd <= parse_hex_dlong(sd);
        report "ena = " & byte_to_string(ctrl) &
               ",txc = " & byte_to_string(txc) &
               ", txd = " & dlong_to_string(txd) &
               ", crc = " & long_to_string(crc) &
               ", valid = " & std_logic'image(valid) &
               ", crc_rom = " & long_to_string(crc_rom) &
               ", valid_rom = " & std_logic'image(valid_rom) &
               ", crc_table = " & long_to_string(crc_table) &
               ", valid_table = " & std_logic'image(valid_table) &
               ", crc_slice = " & long_to_string(crc_slice) &
               ", valid_slice = " & std_logic'image(valid_slice);
      end if;
    end if;
  end process;

  crc_en <= ctrl(0);
  crc_clr <= ctrl(1);

  crc_imp : crc32x64
  port map (
    clk => clk,
    en => crc_en,
    clr => crc_clr,
    din => txd,
    cin => txc,
    dout => crc,
    valid => valid 
  );

  rom_imp : crc32x64rom
  port map (
    clk => clk,
    en => crc_en,
    clr => crc_clr,
    din => txd,
    cin => txc,
    dout => crc_rom,
    valid => valid_rom 
  );

  table_imp : crc32x64_table
  port map (
    clk => clk,
    en => crc_en,
    clr => crc_clr,
    din => txd,
    cin => txc,
    dout => crc_table,
    valid => valid_table 
  );

  slice_imp : crc32x64_slice
  port map (
    clk => clk,
    en => crc_en,
    clr => crc_clr,
    din => txd,
    cin => txc,
    dout => crc_slice,
    valid => valid_slice 
  );


end Behavioral;
