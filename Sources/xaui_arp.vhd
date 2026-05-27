--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    05:40:13 10/06/2016 
-- Design Name:    amc502
-- Module Name:    xaui_arp - RTL
-- Project Name:   amc502 firmware
-- Target Devices: xc7k420t
-- Tool versions:  Vivado 2016.1
-- Description:    Parses ARP packets
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

entity xaui_arp is
  port (
    reset : in  std_logic;
    clk : in  std_logic;
    enable : in  std_logic;
    din : in  std_logic_vector (63 downto 0);
    ip_address : in std_logic_vector(31 downto 0);
    hardware_type : out  std_logic_vector (15 downto 0);
    protocol_type : out  std_logic_vector (15 downto 0);
    hlen : out  std_logic_vector (7 downto 0);
    plen : out  std_logic_vector (7 downto 0);
    operation : out  std_logic_vector (15 downto 0);
    sender_ha : out  std_logic_vector (47 downto 0);
    sender_ip : out  std_logic_vector (31 downto 0);
    target_ha : out  std_logic_vector (47 downto 0);
    target_ip : out  std_logic_vector (31 downto 0);
    matched : out std_logic
  );
end xaui_arp;

architecture rtl of xaui_arp is
  type state_t is ( Idle, Word0, Word1, Word2, Done );
  signal state : state_t := Idle;
  signal matched_address : std_logic;
  signal matched_address_0 : std_logic;
  signal matched_address_1 : std_logic;
begin
  process ( clk, reset, enable ) begin
    if ( clk'event and clk = '1' ) then  -- Registered data is valid on rising edge of clk
      if ( reset = '1' ) then
        hardware_type <= ( others => '0' );
        protocol_type <= ( others => '0' );
        hlen <= ( others => '0' );
        plen <= ( others => '0' );
        operation <= ( others => '0' );
        sender_ha <= ( others => '0' );
        sender_ip <= ( others => '0' );
        target_ha <= ( others => '0' );
        target_ip <= ( others => '0' );
        matched_address <= '1';
        state <= Idle;
      elsif ( enable = '1' ) then
        case state is
          when Idle =>
            protocol_type(7 downto 0) <= din(15 downto 8);
            protocol_type(15 downto 8) <= din(7 downto 0);
            hlen <= din(23 downto 16);
            plen <= din(31 downto 24);
            operation(7 downto 0) <= din(47 downto 40);
            operation(15 downto 8) <= din(39 downto 32);
            sender_ha(47 downto 40) <= din(55 downto 48);
            sender_ha(39 downto 32) <= din(63 downto 56);
            state <= Word0;
          when Word0 =>
            sender_ha(31 downto 24) <= din(7 downto 0);
            sender_ha(23 downto 16) <= din(15 downto 8);
            sender_ha(15 downto 8) <= din(23 downto 16);
            sender_ha(7 downto 0) <= din(31 downto 24);
            sender_ip(7 downto 0) <= din(63 downto 56);
            sender_ip(15 downto 8) <= din(55 downto 48);
            sender_ip(23 downto 16) <= din(47 downto 40);
            sender_ip(31 downto 24) <= din(39 downto 32);
            state <= Word1;
          when Word1 =>
            target_ha(47 downto 40) <= din(7 downto 0);
            target_ha(39 downto 32) <= din(15 downto 8);
            target_ha(31 downto 24) <= din(23 downto 16);
            target_ha(23 downto 16) <= din(31 downto 24);
            target_ha(15 downto 8) <= din(39 downto 32);
            target_ha(7 downto 0) <= din(47 downto 40);
            target_ip(31 downto 24) <= din(55 downto 48);
            target_ip(23 downto 16) <= din(63 downto 56);
            matched_address <= matched_address and matched_address_0;
            state <= Word2;
          when Word2 =>
            target_ip(15 downto 8) <= din(7 downto 0);
            target_ip(7 downto 0) <= din(15 downto 8);
            matched <= matched_address and matched_address_1;
            state <= Done;
          when others =>
            
        end case;
      else
        state <= Idle;
        matched_address <= '1';
      end if;
    end if;
  end process;

  matched_address_0 <= '1' when ip_address(31 downto 16) = din(55 downto 48) & din(63 downto 56) else '0';
  matched_address_1 <= '1' when ip_address(15 downto 0) = din(7 downto 0) & din(15 downto 8) else '0';

end rtl;
