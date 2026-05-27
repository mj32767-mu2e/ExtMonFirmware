--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    10:00:41 06/13/2016 
-- Design Name:    amc502
-- Module Name:    ip - RTL
-- Project Name:   amc502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Parses IP packets
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

entity ip is
  port ( reset : in  std_logic;
         clk : in  std_logic;
         enable : in  std_logic;
         din : in  std_logic_vector (7 downto 0);
         ip_address : in std_logic_vector(31 downto 0);
         ip_version : out std_logic_vector(3 downto 0);
         ip_ihl: out std_logic_vector(3 downto 0);
         ip_length : out std_logic_vector(15 downto 0);
         ip_identification : out std_logic_vector(15 downto 0);
         ip_flags : out std_logic_vector(2 downto 0);
         ip_fragment : out std_logic_vector(12 downto 0);
         ip_ttl : out std_logic_vector(7 downto 0);
         ip_protocol : out std_logic_vector(7 downto 0);
         ip_saddr : out std_logic_vector(31 downto 0);
         ip_daddr : out std_logic_vector(31 downto 0);
         header_cksum_valid : out std_logic;
         data_cksum_valid : out std_logic;
         buffer_clear : out std_logic;   -- asserted to prepare buffers to receive payload data
         icmp_enable : out std_logic;
         udp_enable : out std_logic;
         payload : out std_logic;
         matched : out std_logic
       );
end ip;

architecture RTL of ip is
  type state_t is ( Idle,
                    Version_IHL,
                    DSCP_ENC,
                    Length0,
                    Length1,
                    Identification0,
                    Identification1,
                    Fragment_offset0,
                    Fragment_offset1,
                    Time_to_live,
                    Protocol,
                    Header_checksum0,
                    Header_checksum1,
                    Source_addr0,
                    Source_addr1,
                    Source_addr2,
                    Source_addr3,
                    Dest_addr0,
                    Dest_addr1,
                    Dest_addr2,
                    Dest_addr3,
                    Data0,
                    Data1
                  );
  signal state : state_t := Idle;
  signal checksum : std_logic_vector(15 downto 0);
  signal length : std_logic_vector(15 downto 0);
  signal count : unsigned(15 downto 0);
  signal payload_size : unsigned(15 downto 0);
  signal which_protocol : std_logic_vector(7 downto 0);
  signal icmp_protocol : std_logic;
  signal udp_protocol : std_logic;
  signal matched_address : std_logic;
  signal matched_address_byte0 : std_logic;
  signal matched_address_byte1 : std_logic;
  signal matched_address_byte2 : std_logic;
  signal matched_address_byte3 : std_logic;

  component cksum
  port (
    din : in std_logic_vector(7 downto 0);
    clk : in std_logic;
    enable : in std_logic;
    checksum : out std_logic_vector(15 downto 0)
  );
  end component;

begin

  cksum_imp : cksum
  port map (
    din => din,
    clk => clk,
    enable => enable,
    checksum => checksum
  );

  process ( clk, reset, enable ) begin
    if ( clk'event and clk = '1' ) then    -- registered data is valid on rising edge
      if ( reset = '1' ) then
        payload <= '0';
        icmp_enable <= '0';
        udp_enable <= '0';
        header_cksum_valid <= '0';
        data_cksum_valid <= '0';
        buffer_clear <= '0';
        matched_address <= '1';
        matched <= '0';
        state <= Idle;
      elsif ( enable = '0' ) then
        icmp_enable <= '0';
        udp_enable <= '0';
        payload <= '0';
        buffer_clear <= '0';
        matched_address <= '1';
        state <= idle;
      else
        case state is
          when Idle =>
            header_cksum_valid <= '0';
            data_cksum_valid <= '0';
            ip_version <= din(7 downto 4);
            ip_ihl <= din(3 downto 0);
            matched <= '0';
            state <= Version_IHL;
          when Version_IHL =>
            state <= DSCP_ENC;    -- We would normally latch DSCP & ENC, but we don't use them
          when DSCP_ENC =>
            length(15 downto 8) <= din;
            state <= Length0;
          when Length0 =>
            length(7 downto 0) <= din;
            state <= Length1;
          when Length1 =>
            ip_identification(15 downto 8) <= din;
            state <= Identification0;
          when Identification0 =>
            ip_identification(7 downto 0) <= din;
            count <= payload_size;
            state <= Identification1;
          when Identification1 =>
            ip_flags <= din(7 downto 5);
            ip_fragment(12 downto 8) <= din(4 downto 0);
            state <= Fragment_offset0;
          when Fragment_offset0 =>
            ip_fragment(7 downto 0) <= din;
            state <= Fragment_offset1;
          when Fragment_offset1 =>
            ip_ttl <= din;
            state <= Time_to_live;
          when Time_to_live =>
            which_protocol <= din;
            buffer_clear <= '1';
            state <= Protocol;
          when Protocol =>
            buffer_clear <= '0';    -- only assert it for one clock cycle
            state <= Header_checksum0;
          when Header_checksum0 =>
            state <= Header_checksum1;
          when Header_checksum1 =>
            ip_saddr(31 downto 24) <= din;
            state <= Source_addr0;
          when Source_addr0 =>
            ip_saddr(23 downto 16) <= din;
            state <= Source_addr1;
          when Source_addr1 =>
            ip_saddr(15 downto 8) <= din;
            state <= Source_addr2;
          when Source_addr2 =>
            ip_saddr(7 downto 0) <= din;
            state <= Source_addr3;
          when Source_addr3 =>
            ip_daddr(31 downto 24) <= din;
            matched_address <= matched_address and matched_address_byte0;
            state <= Dest_addr0;
          when Dest_addr0 =>
            ip_daddr(23 downto 16) <= din;
            matched_address <= matched_address and matched_address_byte1;
            state <= Dest_addr1;
          when Dest_addr1 =>
            ip_daddr(15 downto 8) <= din;
            matched_address <= matched_address and matched_address_byte2;
            state <= Dest_addr2;
          when Dest_addr2 =>
            ip_daddr(7 downto 0) <= din;
            matched <= matched_address and matched_address_byte3;
            state <= Dest_addr3;
            if ( payload_size /= 0 ) then
              payload <= '1';
              icmp_enable <= icmp_protocol;
              udp_enable <= udp_protocol;
              count <= count - 1;
            end if;
          when Dest_addr3 =>
            if ( checksum = x"0000" ) then
              header_cksum_valid <= '1';
            end if;
            if ( count /= 0 ) then
              count <= count - 1;
            else
              payload <= '0';
              icmp_enable <= '0';
              udp_enable <= '0';
            end if;
            state <= Data1;
          when others =>
            If ( count /= 0 ) then
              count <= count - 1;
            else
              payload <= '0';
              icmp_enable <= '0';
              udp_enable <= '0';
              if ( checksum = x"0000" ) then
                data_cksum_valid <= '1';
              end if;
            end if;
--  remain in this state until enable is deasserted
        end case;
      end if;
    end if;
  end process;

  ip_length <= length;
  payload_size <= unsigned(length)-20;  -- Accounts for size of header and one extra cycle
  ip_protocol <= which_protocol;
  icmp_protocol <= '1' when which_protocol = x"01" else '0';
  udp_protocol <= '1' when which_protocol = x"11" else '0';

--
--  This matching is not quite correct - it should use the netmask, but it will work on our netowrk
--
  matched_address_byte0 <= '1' when ( ip_address(31 downto 24) = x"00" ) or ( din = ip_address(31 downto 24) ) else '0';
  matched_address_byte1 <= '1' when ( ip_address(23 downto 16) = x"00" ) or ( din = ip_address(23 downto 16) ) else '0';
  matched_address_byte2 <= '1' when ( ip_address(15 downto 8) = x"00" ) or ( din = ip_address(15 downto 8) ) else '0';
  matched_address_byte3 <= '1' when ( ip_address(7 downto 0) = x"00" ) or ( din = ip_address(7 downto 0) ) else '0';

end RTL;
