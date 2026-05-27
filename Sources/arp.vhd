--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    08:44:16 06/06/2013 
-- Design Name:    stib
-- Module Name:    arp - RTL
-- Project Name:   STIB firmware
-- Target Devices: xc4vlx25ff668-10
-- Tool versions:  ISE 14.4 / 14.6
-- Description:    Parses ARP packets
--
-- Dependencies:
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity arp is
    port ( reset : in  std_logic;
           clk : in  std_logic;
           enable : in  std_logic;
           din : in  std_logic_vector (7 downto 0);
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
end arp;

architecture rtl of arp is
  type state_t is ( Idle,
                    Hardware_type0, Hardware_type1,
                    Protocol_type0, Protocol_type1,
                    HA_length, PA_length,
                    Operation0, Operation1,
                    Sender_ha_0, Sender_ha_1, Sender_ha_2, Sender_ha_3, Sender_ha_4, Sender_ha_5,
                    Sender_ip_0, Sender_ip_1, Sender_ip_2, Sender_ip_3,
                    Target_ha_0, Target_ha_1, Target_ha_2, Target_ha_3, Target_ha_4, Target_ha_5,
                    Target_ip_0, Target_ip_1, Target_ip_2, Target_ip_3
                  );
  signal state : state_t := Idle;
  signal matched_address : std_logic;
  signal matched_address_byte0 : std_logic;
  signal matched_address_byte1 : std_logic;
  signal matched_address_byte2 : std_logic;
  signal matched_address_byte3 : std_logic;
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
            hardware_type(15 downto 8) <= din;
            state <= Hardware_type0;
          when Hardware_type0 =>
            hardware_type(7 downto 0) <= din;
            state <= Hardware_type1;
          when Hardware_type1 =>
            protocol_type(15 downto 8) <= din;
            state <= Protocol_type0;
          when Protocol_type0 =>
            protocol_type(7 downto 0) <= din;
            state <= Protocol_type1;
          when Protocol_type1 =>
            hlen <= din;
            state <= Ha_length;
          when Ha_length =>
            plen <= din;
            state <= Pa_length;
          when Pa_length =>
            operation(15 downto 8) <= din;
            state <= Operation0;
          when Operation0 =>
            operation(7 downto 0) <= din;
            state <= Operation1;
          when Operation1 =>
            sender_ha(47 downto 40) <= din;
            state <= Sender_ha_0;
          when Sender_ha_0 =>
            sender_ha(39 downto 32) <= din;
            state <= Sender_ha_1;
          when Sender_ha_1 =>
            sender_ha(31 downto 24) <= din;
            state <= Sender_ha_2;
          when Sender_ha_2 =>
            sender_ha(23 downto 16) <= din;
            state <= Sender_ha_3;
          when Sender_ha_3 =>
            sender_ha(15 downto 8) <= din;
            state <= Sender_ha_4;
          when Sender_ha_4 =>
            sender_ha(7 downto 0) <= din;
            state <= Sender_ha_5;
          when Sender_ha_5 =>
            sender_ip(31 downto 24) <= din;
            state <= Sender_ip_0;
          when Sender_ip_0 =>
            sender_ip(23 downto 16) <= din;
            state <= Sender_ip_1;
          when Sender_ip_1 =>
            sender_ip(15 downto 8) <= din;
            state <= Sender_ip_2;
          when Sender_ip_2 =>
            sender_ip(7 downto 0) <= din;
            state <= Sender_ip_3;
          when Sender_ip_3 =>
            target_ha(47 downto 40) <= din;
            state <= Target_ha_0;
          when Target_ha_0 =>
            target_ha(39 downto 32) <= din;
            state <= Target_ha_1;
          when Target_ha_1 =>
            target_ha(31 downto 24) <= din;
            state <= Target_ha_2;
          when Target_ha_2 =>
            target_ha(23 downto 16) <= din;
            state <= Target_ha_3;
          when Target_ha_3 =>
            target_ha(15 downto 8) <= din;
            state <= Target_ha_4;
          when Target_ha_4 =>
            target_ha(7 downto 0) <= din;
            state <= Target_ha_5;
          when Target_ha_5 =>
            target_ip(31 downto 24) <= din;
            matched_address <= matched_address and matched_address_byte0;
            state <= Target_ip_0;
          when Target_ip_0 =>
            target_ip(23 downto 16) <= din;
            matched_address <= matched_address and matched_address_byte1;
            state <= Target_ip_1;
          when Target_ip_1 =>
            target_ip(15 downto 8) <= din;
            matched_address <= matched_address and matched_address_byte2;
            state <= Target_ip_2;
          when Target_ip_2 =>
            target_ip(7 downto 0) <= din;
            matched <= matched_address and matched_address_byte3;
            state <= Target_ip_3;
          when others =>
        end case;
      else
        state <= Idle;
        matched_address <= '1';
      end if;
    end if;
  end process;

  matched_address_byte0 <= '1' when din = ip_address(31 downto 24) else '0';
  matched_address_byte1 <= '1' when din = ip_address(23 downto 16) else '0';
  matched_address_byte2 <= '1' when din = ip_address(15 downto 8) else '0';
  matched_address_byte3 <= '1' when din = ip_address(7 downto 0) else '0';

end rtl;
