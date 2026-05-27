--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    12:34:00 10/04/2016 
-- Design Name:    amc502
-- Module Name:    xaui_sendpkt - RTL
-- Project Name:   
-- Target Devices: Kintex-7 family
-- Tool versions:  Vivado 2016.1
-- Description:    Sends ARP request packet
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

entity xaui_sendpkt is
  port (
    reset : in std_logic;
    clk : in std_logic;
    strobe : in std_logic;
    issue_arp_request : out std_logic;
    arptab_lookup_ip : out std_logic_vector(31 downto 0);
    arptab_read : out std_logic;
    arptab_found : in std_logic;
    arptab_missing : in std_logic;
    dst_ha : in std_logic_vector(47 downto 0);
    src_ha : in std_logic_vector(47 downto 0);
    src_ip : in std_logic_vector(31 downto 0);
    dst_ip : in std_logic_vector(31 downto 0);
    src_port : in std_logic_vector(15 downto 0);
    dst_port : in std_logic_vector(15 downto 0);
    udp_buffer_checksum : in std_logic_vector(15 downto 0);
    udp_buffer_length : in std_logic_vector(11 downto 0);
    addr : out std_logic_vector(7 downto 0);
    din : in std_logic_vector(63 downto 0);
    dout : out std_logic_vector(63 downto 0);
    cout : out std_logic_vector(7 downto 0);
    fcs : out std_logic;
    request : out std_logic;
    grant : in std_logic
  );
end xaui_sendpkt;

architecture RTL of xaui_sendpkt is

  function htons(
    din : std_logic_vector(15 downto 0)
  ) return std_logic_vector is
    variable dout : std_logic_vector(15 downto 0);
  begin
    dout(7 downto 0) := din(15 downto 8);
    dout(15 downto 8) := din(7 downto 0);
    return dout;
  end;

  function add_cksum(
    sum : std_logic_vector(15 downto 0);
    din : std_logic_vector(15 downto 0)
  )
  return std_logic_vector is
    variable next_sum : unsigned(18 downto 0);
  begin
    next_sum := "000" & unsigned(sum);
    next_sum := next_sum + unsigned(din);
    if ( next_sum(18) = '0' ) then
      next_sum := "000" & next_sum(15 downto 0) + next_sum(17 downto 16);
    else
      next_sum := "000" & next_sum(15 downto 0) - not next_sum(17 downto 16) - 1;
    end if;
    return std_logic_vector(next_sum(15 downto 0));
  end;

  type State_t is ( Idle, RequestAccess, ArptabLookup, DoingArptabLookup, Preamble,
                    Word0, Word1, Word2, Word3, Word4, Word5, SendData,
                    FrameCheckSum, Done );
  signal state : State_t := Idle;

  signal last_strobe : std_logic_vector(2 downto 0);
  signal total_length : unsigned(15 downto 0);
  signal udp_length : unsigned(15 downto 0);
  signal count : unsigned(12 downto 0);
  signal data_word : std_logic_vector(63 downto 0);
  signal buffer_address : unsigned(7 downto 0);
  signal ipheader_cksum : std_logic_vector(15 downto 0) := ( others => '0' );
  signal udp_cksum_0 : std_logic_vector(15 downto 0) := ( others => '0' );
  signal udp_cksum_1 : std_logic_vector(15 downto 0) := ( others => '0' );
  signal udp_cksum : std_logic_vector(15 downto 0) := ( others => '0' );

  signal dst_ha_r : std_logic_vector(47 downto 0);
  signal src_ha_r : std_logic_vector(47 downto 0);
  signal src_ip_r : std_logic_vector(31 downto 0);
  signal dst_ip_r : std_logic_vector(31 downto 0);
  signal src_port_r : std_logic_vector(15 downto 0);
  signal dst_port_r : std_logic_vector(15 downto 0);
  signal udp_buffer_checksum_r : std_logic_vector(15 downto 0);
  signal udp_buffer_length_r : std_logic_vector(11 downto 0);

begin

  process ( clk, reset )
    variable new_hdr_sum : std_logic_vector(15 downto 0);
  begin
    if ( clk'event and clk = '1' ) then     -- data is valid on the rising edge
      udp_buffer_checksum_r <= udp_buffer_checksum;
      udp_buffer_length_r <= udp_buffer_length;
      if ( reset = '1' ) then
        request <= '0';
        arptab_read <= '0';
        issue_arp_request <= '0';
        dout <= x"0707070707070707";
        cout <= x"ff";
        fcs <= '0';
        buffer_address <= ( others => '0' );
        addr <= ( others => '0' );
        state <= Idle;
      else
        case state is
          when Idle =>
            if ( strobe = '1' and last_strobe(0) = '0' ) then
              request <= '1';
              arptab_read <= '0';
              issue_arp_request <= '0';
              dout <= x"0707070707070707";
              cout <= x"ff";
              fcs <= '0';
              src_ha_r <= src_ha;
              src_ip_r <= src_ip;
              dst_ip_r <= dst_ip;
              src_port_r <= src_port;
              dst_port_r <= dst_port;
              state <= RequestAccess;
            else
              request <= '0';
              arptab_read <= '0';
              issue_arp_request <= '0';
              buffer_address <= ( others => '0' );
              addr <= ( others => '0' );
              dout <= x"0707070707070707";
              cout <= x"ff";
              fcs <= '0';
              state <= Idle;
            end if;
          when RequestAccess =>
            request <= '1';
            if ( grant = '1' ) then
              state <= ArptabLookup;
              arptab_read <= '1';
            else
              state <= RequestAccess;
            end if;
          when ArptabLookup =>
            total_length <= to_unsigned(to_integer(unsigned(udp_buffer_length_r))+28,16);
            udp_length <= to_unsigned(to_integer(unsigned(udp_buffer_length_r))+8,16);
            count <= to_unsigned((to_integer(unsigned(udp_buffer_length_r))-2)/8,13);
            udp_cksum_0 <= add_cksum(udp_buffer_checksum_r,x"0011");
            udp_cksum_1 <= add_cksum(src_ip_r(15 downto 0),src_ip_r(31 downto 16));
            arptab_read <= '0';
            state <= DoingArptabLookup;
          when DoingArptabLookup =>
            if ( arptab_found = '1' ) then
              dst_ha_r <= dst_ha;
              state <= Preamble;
            elsif ( arptab_missing = '1' ) then
              issue_arp_request <= '1';
              state <= Done;
            else
              state <= DoingArptabLookup;
            end if;
          when Preamble =>
            udp_cksum_0 <= add_cksum(udp_cksum_0,dst_port_r);
            udp_cksum_1 <= add_cksum(udp_cksum_1,dst_ip_r(15 downto 0));
            dout <= x"d5555555555555fb";
            cout <= x"01";
            state <= Word0;
          when Word0 =>
            udp_cksum_0 <= add_cksum(udp_cksum_0,src_port_r);
            udp_cksum_1 <= add_cksum(udp_cksum_1,dst_ip_r(31 downto 16));
            ipheader_cksum <= add_cksum(x"c511",std_logic_vector(total_length));
            dout <= src_ha_r(39 downto 32) & src_ha_r(47 downto 40) &
                    dst_ha_r(7 downto 0) & dst_ha_r(15 downto 8) &
                    dst_ha_r(23 downto 16) & dst_ha_r(31 downto 24) &
                    dst_ha_r(39 downto 32) & dst_ha_r(47 downto 40);
            cout <= x"00";
            state <= Word1;
          when Word1 =>
            udp_cksum_0 <= add_cksum(udp_cksum_0,std_logic_vector(udp_length));
            udp_cksum_1 <= add_cksum(udp_cksum_1,std_logic_vector(udp_length));
            new_hdr_sum := add_cksum(ipheader_cksum,src_ip_r(15 downto 0));
            ipheader_cksum <= add_cksum(new_hdr_sum,src_ip_r(31 downto 16));
            dout <= x"00450008" &
                    src_ha_r(7 downto 0) & src_ha_r(15 downto 8) &
                    src_ha_r(23 downto 16) & src_ha_r(31 downto 24);
            cout <= x"00";
            state <= Word2;
          when Word2 =>
            udp_cksum <= add_cksum(udp_cksum_0,udp_cksum_1);
            new_hdr_sum := add_cksum(ipheader_cksum,dst_ip_r(15 downto 0));
            ipheader_cksum <= add_cksum(new_hdr_sum,dst_ip_r(31 downto 16));

            dout <= x"114000400000" &
                    std_logic_vector(total_length(7 downto 0)) &
                    std_logic_vector(total_length(15 downto 8));
            cout <= x"00";
            state <= Word3;
          when Word3 =>
            dout <= dst_ip_r(23 downto 16) & dst_ip_r(31 downto 24) &
                    src_ip_r(7 downto 0) & src_ip_r(15 downto 8) &
                    src_ip_r(23 downto 16) & src_ip_r(31 downto 24) &
                    not std_logic_vector(ipheader_cksum(7 downto 0)) &
                    not std_logic_vector(ipheader_cksum(15 downto 8));
            cout <= x"00";
            state <= Word4;
          when Word4 =>
            dout <= std_logic_vector(udp_length(7 downto 0)) &
                    std_logic_vector(udp_length(15 downto 8)) &
                    src_port_r(7 downto 0) & src_port_r(15 downto 8) &
                    dst_port_r(7 downto 0) & dst_port_r(15 downto 8) &
                    dst_ip_r(7 downto 0) & dst_ip_r(15 downto 8);
            cout <= x"00";
            data_word <= din;
            buffer_address <= buffer_address + 1;
            addr <= std_logic_vector(buffer_address+1);
            state <= Word5;
          when Word5 =>
            dout <= data_word(47 downto 0) &
                    not std_logic_vector(udp_cksum(7 downto 0)) &
                    not std_logic_vector(udp_cksum(15 downto 8));
            cout <= x"00";
            data_word <= din;
            buffer_address <= buffer_address + 1;
            addr <= std_logic_vector(buffer_address+1);
            state <= SendData;
          when SendData =>
            data_word <= din;
            buffer_address <= buffer_address + 1;
            addr <= std_logic_vector(buffer_address+1);
            if ( count /= 0 ) then
              dout <= din(47 downto 0) & data_word(63 downto 48);
              cout <= x"00";
              state <= SendData;
              count <= count - 1;
            else
              dout <= x"bcfd00000000" & data_word(63 downto 48);
              cout <= x"fc";
              state <= FrameCheckSum;
            end if;
          when FrameCheckSum =>
            dout <= x"0707070707070707";
            cout <= x"ff";
            fcs <= '1';
            state <= Done;
          when Done =>
            dout <= x"0707070707070707";
            cout <= x"ff";
            fcs <= '0';
            issue_arp_request <= '0';
            arptab_read <= '0';
            state <= Idle;
        end case;
      end if;
      last_strobe <= strobe & last_strobe(last_strobe'left downto 1);
    end if;
  end process;

  arptab_lookup_ip <= dst_ip_r;

end RTL;
