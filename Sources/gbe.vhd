----------------------------------------------------------------------------------
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    05/31/2013 
-- Design Name:    mu2e_amc502
-- Package Name:   gbe
-- Project Name:   Mu2e
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    This defines the interface to the GBE slave.
--
-- Dependencies:
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library hep337dev;
use hep337dev.iobus.all;

package gbe is

  function char_to_digit( c : character ) return natural;
  function char_to_hex_digit( c : character ) return std_logic_vector;
  function string_to_hwaddr( addr : string ) return std_logic_vector;
  function string_to_ipaddr( addr : string ) return std_logic_vector;

  type stream_data_array_t is array(integer range <>) of std_logic_vector(31 downto 0);
  type stream_free_array_t is array(integer range <>) of std_logic_vector(15 downto 0);

  component gbe_interface is
    generic (
      mac_address : string := "00:00:00:00:00:00";
      ip_address : string := "0.0.0.0";
      netmask : string := "0.0.0.0";
      gateway : string := "0.0.0.0";
      jumpers : boolean := false;
      nstream : integer := 1;
      dhcp : boolean := false
    );
    port (
      busclk : in std_logic;
      iobus : in iobus_t;
      write_data : out std_logic_vector(31 downto 0);
      iobus_ready : out std_logic;
      interrupt : out std_logic;
      reset_out : out std_logic;
      reset_done : in std_logic;
      mmcm_locked : in std_logic;
      jumpered_address : in std_logic_vector(6 downto 0);
      gmii_clk : in std_logic;
      gmii_txd : out std_logic_vector(7 downto 0);
      gmii_tx_en : out std_logic;
      gmii_tx_er : out std_logic;
      gmii_rxd : in std_logic_vector(7 downto 0);
      gmii_rx_dv : in std_logic;
      gmii_rx_er : in std_logic;
      gbe_stream_clka : out std_logic;
      gbe_stream_wren : in std_logic_vector(nstream-1 downto 0);
      gbe_stream_strobe : in std_logic_vector(nstream-1 downto 0);
      gbe_stream_data : in stream_data_array_t;
      gbe_stream_free : out stream_free_array_t
    ); 
  end component;

end package gbe;

PACKAGE BODY gbe IS

  FUNCTION char_to_digit( C : CHARACTER ) RETURN NATURAL IS
  BEGIN
    CASE C IS
      WHEN '0' => RETURN 0;
      WHEN '1' => RETURN 1;
      WHEN '2' => RETURN 2;
      WHEN '3' => RETURN 3;
      WHEN '4' => RETURN 4;
      WHEN '5' => RETURN 5;
      WHEN '6' => RETURN 6;
      WHEN '7' => RETURN 7;
      WHEN '8' => RETURN 8;
      WHEN '9' => RETURN 9;
      WHEN OTHERS => ASSERT FALSE REPORT "Bad decimal digit" SEVERITY FAILURE;
    END CASE;
    RETURN 0;
  END char_to_digit;

  FUNCTION char_to_hex_digit( C : CHARACTER ) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    CASE C IS
      WHEN '0' => RETURN X"0";
      WHEN '1' => RETURN X"1";
      WHEN '2' => RETURN X"2";
      WHEN '3' => RETURN X"3";
      WHEN '4' => RETURN X"4";
      WHEN '5' => RETURN X"5";
      WHEN '6' => RETURN X"6";
      WHEN '7' => RETURN X"7";
      WHEN '8' => RETURN X"8";
      WHEN '9' => RETURN X"9";
      WHEN 'a' => RETURN X"A";
      WHEN 'A' => RETURN X"A";
      WHEN 'b' => RETURN X"B";
      WHEN 'B' => RETURN X"B";
      WHEN 'c' => RETURN X"C";
      WHEN 'C' => RETURN X"C";
      WHEN 'd' => RETURN X"D";
      WHEN 'D' => RETURN X"D";
      WHEN 'e' => RETURN X"E";
      WHEN 'E' => RETURN X"E";
      WHEN 'f' => RETURN X"F";
      WHEN 'F' => RETURN X"F";
      WHEN OTHERS => ASSERT FALSE REPORT "Bad hex digit" SEVERITY FAILURE;
    END CASE;
    RETURN X"0";
  END char_to_hex_digit;

  FUNCTION string_to_hwaddr( ADDR : STRING ) RETURN STD_LOGIC_VECTOR IS
    VARIABLE BYTE_INDEX : NATURAL := 0;
    VARIABLE NIBBLE_INDEX : NATURAL := 0;
    VARIABLE INDEX : NATURAL := 0;
    VARIABLE HWADDR : STD_LOGIC_VECTOR(47 DOWNTO 0) := ( OTHERS => '0' );
  BEGIN
    IF ( ADDR'LENGTH = 17 ) THEN
      L: FOR I IN ADDR'REVERSE_RANGE LOOP
        IF ( ADDR(I) = ':' ) THEN
          BYTE_INDEX := BYTE_INDEX + 1;
          NIBBLE_INDEX := 0;
        ELSE
          INDEX := ( BYTE_INDEX * 8 ) + ( NIBBLE_INDEX * 4 );
          HWADDR(INDEX+3 DOWNTO INDEX) := char_to_hex_digit(ADDR(I));
          NIBBLE_INDEX := NIBBLE_INDEX + 1;
        END IF;
      END LOOP L;
    ELSE
      ASSERT FALSE REPORT "Bad MAC address format" SEVERITY FAILURE;
    END IF;
    RETURN HWADDR;
  END string_to_hwaddr;

  FUNCTION string_to_ipaddr( ADDR : STRING ) RETURN STD_LOGIC_VECTOR IS
    VARIABLE BYTE_INDEX : NATURAL := 0;
    VARIABLE TMP : NATURAL := 0;
    VARIABLE MULT : NATURAL := 1;
    VARIABLE INDEX : NATURAL := 0;
    VARIABLE IPADDR : STD_LOGIC_VECTOR(31 DOWNTO 0) := ( OTHERS => '0' );
  BEGIN
    L: FOR I IN ADDR'REVERSE_RANGE LOOP
      IF ( ADDR(I) = '.' ) THEN
        BYTE_INDEX := BYTE_INDEX + 1;
        MULT := 1;
        TMP := 0;
      ELSE
        TMP := TMP + MULT * char_to_digit(ADDR(I));
        INDEX := BYTE_INDEX * 8;
        IPADDR(INDEX+7 DOWNTO INDEX) := STD_LOGIC_VECTOR(TO_UNSIGNED(TMP,8));
        MULT := MULT * 10;
      END IF;
    END LOOP L;
    RETURN IPADDR;
  END string_to_ipaddr;

END gbe;

