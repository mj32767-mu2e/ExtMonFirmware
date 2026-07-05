----------------------------------------------------------------------------------
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    10/1/2016 
-- Design Name:    mu2e_amc502
-- Package Name:   xaui
-- Project Name:   Mu2e
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    This defines the interface to the 10GbE slave.
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

library hep337dev;
use hep337dev.iobus.all;

package xaui is

  function char_to_digit( c : character ) return natural;
  function char_to_hex_digit( c : character ) return std_logic_vector;
  function string_to_hwaddr( addr : string ) return std_logic_vector;
  function string_to_ipaddr( addr : string ) return std_logic_vector;

  type xstream_data_array_t is array(integer range <>) of std_logic_vector(63 downto 0);
  type xstream_free_array_t is array(integer range <>) of std_logic_vector(15 downto 0);

  component xaui_interface is
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
      ready_in : in std_logic;
      xgmii_rxclk : in std_logic;
      xgmii_txclk : in std_logic;
      xgmii_txd : out std_logic_vector(63 downto 0);
      xgmii_txc : out std_logic_vector(7 downto 0);
      xgmii_rxd : in std_logic_vector(63 downto 0);
      xgmii_rxc : in std_logic_vector(7 downto 0);
      xgmii_clk_lock : in std_logic;
      jumpered_address : in std_logic_vector(6 downto 0);
      configuration_vector_out : out std_logic_vector(6 downto 0);
      status_vector_in : in std_logic_vector(7 downto 0);
      sendpkt_trigger : in std_logic;
      udp_received : out std_logic;
      xgbe_stream_clka : out std_logic;
      xgbe_stream_wren : in std_logic_vector(nstream-1 downto 0);
      xgbe_stream_strobe : in std_logic_vector(nstream-1 downto 0);
      xgbe_stream_data : in xstream_data_array_t;
      xgbe_stream_free : out xstream_free_array_t;
      xgbe_trigger_stream_enable : out std_logic;
      xgbe_trigger_stream_data : out std_logic_vector(63 downto 0);
      debug_in : in std_logic_vector(5 downto 0)
    ); 
  end component;

end package xaui;

package body xaui is

  function char_to_digit( c : character ) return natural is
  begin
    case c is
      when '0' => return 0;
      when '1' => return 1;
      when '2' => return 2;
      when '3' => return 3;
      when '4' => return 4;
      when '5' => return 5;
      when '6' => return 6;
      when '7' => return 7;
      when '8' => return 8;
      when '9' => return 9;
      when others => assert false report "bad decimal digit" severity failure;
    end case;
    return 0;
  end char_to_digit;

  function char_to_hex_digit( c : character ) return std_logic_vector is
  begin
    case c is
      when '0' => return x"0";
      when '1' => return x"1";
      when '2' => return x"2";
      when '3' => return x"3";
      when '4' => return x"4";
      when '5' => return x"5";
      when '6' => return x"6";
      when '7' => return x"7";
      when '8' => return x"8";
      when '9' => return x"9";
      when 'a' => return x"a";
      when 'A' => return x"a";
      when 'b' => return x"b";
      when 'B' => return x"b";
      when 'c' => return x"c";
      when 'C' => return x"c";
      when 'd' => return x"d";
      when 'D' => return x"d";
      when 'e' => return x"e";
      when 'E' => return x"e";
      when 'f' => return x"f";
      when 'F' => return x"f";
      when others => assert false report "bad hex digit" severity failure;
    end case;
    return x"0";
  end char_to_hex_digit;

  function string_to_hwaddr( addr : string ) return std_logic_vector is
    variable byte_index : natural := 0;
    variable nibble_index : natural := 0;
    variable index : natural := 0;
    variable hwaddr : std_logic_vector(47 downto 0) := ( others => '0' );
  begin
    if ( addr'length = 17 ) then
      l: for i in addr'reverse_range loop
        if ( addr(i) = ':' ) then
          byte_index := byte_index + 1;
          nibble_index := 0;
        else
          index := ( byte_index * 8 ) + ( nibble_index * 4 );
          hwaddr(index+3 downto index) := char_to_hex_digit(addr(i));
          nibble_index := nibble_index + 1;
        end if;
      end loop l;
    else
      assert false report "bad mac address format" severity failure;
    end if;
    return hwaddr;
  end string_to_hwaddr;

  function string_to_ipaddr( addr : string ) return std_logic_vector is
    variable byte_index : natural := 0;
    variable tmp : natural := 0;
    variable mult : natural := 1;
    variable index : natural := 0;
    variable ipaddr : std_logic_vector(31 downto 0) := ( others => '0' );
  begin
    l: for i in addr'reverse_range loop
      if ( addr(i) = '.' ) then
        byte_index := byte_index + 1;
        mult := 1;
        tmp := 0;
      else
        tmp := tmp + mult * char_to_digit(addr(i));
        index := byte_index * 8;
        ipaddr(index+7 downto index) := std_logic_vector(to_unsigned(tmp,8));
        mult := mult * 10;
      end if;
    end loop l;
    return ipaddr;
  end string_to_ipaddr;

END xaui;
