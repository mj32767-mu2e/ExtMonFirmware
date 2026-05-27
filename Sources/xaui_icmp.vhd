--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    10:16:52 06/13/2016 
-- Design Name:    amc502
-- Module Name:    xaui_icmp - RTL
-- Project Name:   amc502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Parses 10GbE ICMP packets
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

entity xaui_icmp is
port (
  reset : in  std_logic;
  clk : in  std_logic;
  enable : in  std_logic;
  din : in  std_logic_vector (63 downto 0);
  icmp_type : out std_logic_vector(7 downto 0);
  icmp_code : out std_logic_vector(7 downto 0);
  icmp_cksum : out std_logic_vector(15 downto 0);
  echo_ident : out std_logic_vector(15 downto 0);
  echo_seq : out std_logic_vector(15 downto 0);
  icmp_data_we : out std_logic
);
end xaui_icmp;

architecture RTL of xaui_icmp is
  type state_t is ( Idle, IpHeader1, IpHeader2, Payload );
  signal state : state_t := Idle;
  signal gated_icmp_data_we : std_logic := '0';
begin

  process ( clk, reset, enable ) begin
    if ( clk'event and clk = '1' ) then
      if ( reset = '1' ) then
        icmp_type <= ( others => '0' );
        icmp_code <= ( others => '0' );
        icmp_cksum <= ( others => '0' );
        echo_ident <= ( others => '0' );
        echo_seq <= ( others => '0' );
        gated_icmp_data_we <= '0';
        state <= Idle;
      else
        case state is
        when Idle =>
          if ( enable = '1' ) then
            state <= IpHeader1;
          else
            state <= Idle;
          end if;
        when IpHeader1 =>
          icmp_type <= din(23 downto 16);
          icmp_code <= din(31 downto 24);
          icmp_cksum(15 downto 8) <= din(39 downto 32);
          icmp_cksum(7 downto 0) <= din(47 downto 40);
          echo_ident(15 downto 8) <= din(55 downto 48);
          echo_ident(7 downto 0) <= din(63 downto 56);
          state <= IpHeader2;
        when IpHeader2 =>
          echo_seq(15 downto 8) <= din(7 downto 0);
          echo_seq(7 downto 0) <= din(15 downto 8);
          state <= Payload;
        when Payload =>
          if ( enable = '0' ) then
            state <= Idle;
          else
            state <= Payload;
          end if;
        end case;
      end if;
    end if;
  end process;

  icmp_data_we <= enable;

end RTL;
