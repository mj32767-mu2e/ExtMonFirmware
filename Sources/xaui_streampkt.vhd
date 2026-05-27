--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    13:15:00 12/25/2018 
-- Design Name:    amc502
-- Module Name:    xaui_streampkt - RTL
-- Project Name:   
-- Target Devices: Kintex-7 family
-- Tool versions:  Vivado 2016.1
-- Description:    streams data over XAUI interface
--
-- Dependencies:
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--  Some reporting functions are only used for simulation and are ignored
--  in the actual implementation.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity xaui_streampkt is
  generic (
    index : integer := 0
  );
  port (
    reset : in std_logic;
    clk : in std_logic;
    strobe : in std_logic;
    busy : out std_logic;
    done : out std_logic;
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
    buffer_cksum : in std_logic_vector(15 downto 0);
    buffer_length : in std_logic_vector(11 downto 0);
    buffer_rden : out std_logic;
    buffer_data : in std_logic_vector(63 downto 0);
    dout : out std_logic_vector(63 downto 0);
    cout : out std_logic_vector(7 downto 0);
    fcs : out std_logic;
    request : out std_logic;
    grant : in std_logic;
    debug_state : out std_logic_vector(3 downto 0)
  );
end xaui_streampkt;

architecture RTL of xaui_streampkt is

--
--  Revert back to 27-Dec-2018 version if necessary
--
  function add_cksum(
    sum : std_logic_vector(15 downto 0);
    din : std_logic_vector(15 downto 0)
  )
  return std_logic_vector is
    variable next_sum : unsigned(16 downto 0);
  begin
    next_sum := unsigned('0' & din) + unsigned('0' & sum);
    if ( next_sum(16) = '1' ) then
      next_sum := ( "0" & next_sum(15 downto 0) ) + 1;
    end if;
    return std_logic_vector(next_sum(15 downto 0));
  end;

  function print_hex_short( v : std_logic_vector(15 downto 0) ) return string is
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
  end print_hex_short;

  function print_hex_long( v : std_logic_vector(63 downto 0) ) return string is
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
  end print_hex_long;

  type State_t is ( Idle, RequestAccess, ArptabLookup, DoingArptabLookup, Preamble,
                    Word0, Word1, Word2, Word3, Word4, Word5, SendData,
                    FrameCheckSum, FinallyDone, InterFrameGap0, InterFrameGap1 );
  signal state : State_t := Idle;

  signal last_strobe : std_logic_vector(2 downto 0) := "000";
  signal total_length : unsigned(15 downto 0);
  signal udp_length : unsigned(15 downto 0);
  signal count : unsigned(11 downto 0);
  signal data_word : std_logic_vector(63 downto 0);
  signal ipheader_cksum : std_logic_vector(15 downto 0) := ( others => '0' );
  signal udp_cksum_0 : std_logic_vector(15 downto 0) := ( others => '0' );
  signal udp_cksum_1 : std_logic_vector(15 downto 0) := ( others => '0' );
  signal udp_cksum_01 : std_logic_vector(15 downto 0) := ( others => '0' );
  signal udp_cksum_2 : std_logic_vector(15 downto 0) := ( others => '0' );
  signal udp_cksum_3 : std_logic_vector(15 downto 0) := ( others => '0' );
  signal udp_cksum_23 : std_logic_vector(15 downto 0) := ( others => '0' );
  signal udp_cksum_0123 : std_logic_vector(15 downto 0) := ( others => '0' );
  signal udp_cksum : std_logic_vector(15 downto 0) := ( others => '0' );

  signal dst_ha_r : std_logic_vector(47 downto 0);
  signal src_ha_r : std_logic_vector(47 downto 0);
  signal src_ip_r : std_logic_vector(31 downto 0);
  signal dst_ip_r : std_logic_vector(31 downto 0);
  signal src_port_r : std_logic_vector(15 downto 0);
  signal dst_port_r : std_logic_vector(15 downto 0);
  signal udp_buffer_checksum_r : std_logic_vector(15 downto 0);
  signal udp_buffer_length_r : std_logic_vector(11 downto 0);

  attribute mark_debug : string;
  attribute mark_debug of last_strobe : signal is "true";
  attribute mark_debug of debug_state : signal is "true";

begin

  process ( clk, reset )
    variable new_hdr_sum : std_logic_vector(15 downto 0);
    variable txd : std_logic_vector(63 downto 0);
    variable total_length_v : std_logic_vector(15 downto 0);
    variable count_v : std_logic_vector(15 downto 0);
    variable udp_length_v : std_logic_vector(15 downto 0);
  begin
    if ( clk'event and clk = '1' ) then     -- data is valid on the rising edge
      if ( reset = '1' ) then
        request <= '0';
        arptab_read <= '0';
        issue_arp_request <= '0';
        buffer_rden <= '0';
        dout <= x"0707070707070707";
        cout <= x"ff";
        fcs <= '0';
        state <= Idle;
      else
        last_strobe <= strobe & last_strobe(last_strobe'left downto 1);
        case state is
          when Idle =>
            debug_state <= "0001";
            if ( last_strobe = "100" ) then
              report "Idle state - received strobe.";
              request <= '1';
              done <= '0';
              arptab_read <= '0';
              buffer_rden <= '0';
              issue_arp_request <= '0';
              dout <= x"0707070707070707";
              cout <= x"ff";
              fcs <= '0';
              src_ha_r <= src_ha;
              src_ip_r <= src_ip;
              dst_ip_r <= dst_ip;
              src_port_r <= src_port;
              dst_port_r <= dst_port;
              report "Got strobe, requesting access.";
              state <= RequestAccess;
            else
              request <= '0';
              done <= '0';
              arptab_read <= '0';
              issue_arp_request <= '0';
              buffer_rden <= '0';
              dout <= x"0707070707070707";
              cout <= x"ff";
              fcs <= '0';
              state <= Idle;
            end if;
          when RequestAccess =>
            debug_state <= "0010";
            request <= '1';
            udp_buffer_checksum_r <= buffer_cksum;
            udp_buffer_length_r <= buffer_length;
            if ( grant = '1' ) then
              state <= ArptabLookup;
              arptab_read <= '1';
            else
              state <= RequestAccess;
            end if;
          when ArptabLookup =>
            debug_state <= "0011";
            report "UDP buffer checksum = " & print_hex_short(udp_buffer_checksum_r);
            report "UDP buffer length = " & print_hex_short("0000" & udp_buffer_length_r);
            total_length <= "0000" & unsigned(udp_buffer_length_r)+28;
            total_length_v := std_logic_vector("0000" & unsigned(udp_buffer_length_r)+28);
            udp_length <= unsigned("0000" & udp_buffer_length_r)+8;
            udp_length_v := std_logic_vector(unsigned("0000" & udp_buffer_length_r)+8);
            count <= unsigned(udp_buffer_length_r)/8-1;
            count_v := std_logic_vector("0000" & unsigned(udp_buffer_length_r)/8-1);
            udp_cksum_0 <= add_cksum(udp_buffer_checksum_r,x"0011");
            udp_cksum_1 <= add_cksum(src_ip_r(15 downto 0),src_ip_r(31 downto 16));
            udp_cksum_2 <= add_cksum(dst_ip_r(15 downto 0),dst_ip_r(31 downto 16));
            udp_cksum_3 <= add_cksum(dst_port_r,src_port_r);

            report "        total length = " & print_hex_short(total_length_v);
            report "          udp length = " & print_hex_short(udp_length_v);
            report "   buffer word count = " & print_hex_short(count_v);
            report "UDP buffer checksum  = " & print_hex_short(udp_buffer_checksum_r);
            report "UDP header checksum += " & print_hex_short(x"0011");
            report "UDP header checksum += " & print_hex_short(src_ip_r(15 downto 0));
            report "UDP header checksum += " & print_hex_short(src_ip_r(31 downto 16));
            report "UDP header checksum += " & print_hex_short(dst_ip_r(15 downto 0));
            report "UDP header checksum += " & print_hex_short(dst_ip_r(31 downto 16));
            report "UDP header checksum += " & print_hex_short(src_port_r);
            report "UDP header checksum += " & print_hex_short(dst_port_r);
            arptab_read <= '0';
            state <= DoingArptabLookup;
          when DoingArptabLookup =>
            debug_state <= "0100";
            if ( arptab_found = '1' ) then
              dst_ha_r <= dst_ha;
              state <= Preamble;
            elsif ( arptab_missing = '1' ) then
              issue_arp_request <= '1';
              state <= FinallyDone;
            else
              state <= DoingArptabLookup;
            end if;
          when Preamble =>
            debug_state <= "0101";
            udp_cksum_01 <= add_cksum(udp_cksum_0,udp_cksum_1);
            udp_cksum_23 <= add_cksum(udp_cksum_2,udp_cksum_3);
            txd := x"d5555555555555fb";
            dout <= txd;
            cout <= x"01";
            report "XAUI tx = " & print_hex_long(txd);
            state <= Word0;
          when Word0 =>
            debug_state <= "0110";
            udp_cksum_0123 <= add_cksum(udp_cksum_01,udp_cksum_23);
            ipheader_cksum <= add_cksum(x"c511",std_logic_vector(total_length));
            txd := src_ha_r(39 downto 32) & src_ha_r(47 downto 40) &
                   dst_ha_r(7 downto 0) & dst_ha_r(15 downto 8) &
                   dst_ha_r(23 downto 16) & dst_ha_r(31 downto 24) &
                   dst_ha_r(39 downto 32) & dst_ha_r(47 downto 40);
            dout <= txd;
            cout <= x"00";
            report "XAUI tx = " & print_hex_long(txd);
            state <= Word1;
          when Word1 =>
            debug_state <= "0111";
            udp_cksum <= add_cksum(udp_cksum_0123,std_logic_vector(udp_length(udp_length'left-1 downto 0) & '0'));
            report "UDP header checksum += " & print_hex_short(std_logic_vector(udp_length));
            report "UDP header checksum += " & print_hex_short(std_logic_vector(udp_length));
            new_hdr_sum := add_cksum(ipheader_cksum,src_ip_r(15 downto 0));
            ipheader_cksum <= add_cksum(new_hdr_sum,src_ip_r(31 downto 16));
            txd := x"00450008" &
                   src_ha_r(7 downto 0) & src_ha_r(15 downto 8) &
                   src_ha_r(23 downto 16) & src_ha_r(31 downto 24);
            dout <= txd;
            cout <= x"00";
            report "XAUI tx = " & print_hex_long(txd) & "  (1)";
            state <= Word2;
          when Word2 =>
            debug_state <= "1000";
            report "Final UDP header checksum = " &
                   print_hex_short( not std_logic_vector(udp_cksum(7 downto 0)) &
                                    not std_logic_vector(udp_cksum(15 downto 8)) );
            new_hdr_sum := add_cksum(ipheader_cksum,dst_ip_r(15 downto 0));
            ipheader_cksum <= add_cksum(new_hdr_sum,dst_ip_r(31 downto 16));

            txd := x"114000400000" &
                   std_logic_vector(total_length(7 downto 0)) &
                   std_logic_vector(total_length(15 downto 8));
            dout <= txd;
            cout <= x"00";
            report "XAUI tx = " & print_hex_long(txd) & "  (2)";
            state <= Word3;
          when Word3 =>
            debug_state <= "1001";
            txd := dst_ip_r(23 downto 16) & dst_ip_r(31 downto 24) &
                   src_ip_r(7 downto 0) & src_ip_r(15 downto 8) &
                   src_ip_r(23 downto 16) & src_ip_r(31 downto 24) &
                   not std_logic_vector(ipheader_cksum(7 downto 0)) &
                   not std_logic_vector(ipheader_cksum(15 downto 8));
            dout <= txd;
            buffer_rden <= '1';  -- Advance the read pointer on the next cycle
            cout <= x"00";
            report "XAUI tx = " & print_hex_long(txd) & "  (3)";
            state <= Word4;
          when Word4 =>
            debug_state <= "1010";
            txd := std_logic_vector(udp_length(7 downto 0)) &
                   std_logic_vector(udp_length(15 downto 8)) &
                   src_port_r(7 downto 0) & src_port_r(15 downto 8) &
                   dst_port_r(7 downto 0) & dst_port_r(15 downto 8) &
                   dst_ip_r(7 downto 0) & dst_ip_r(15 downto 8);
            dout <= txd;
            cout <= x"00";
            data_word <= buffer_data;   -- Latch the data word
            buffer_rden <= '1';         -- Advance the read pointer on the next cycle
            report "XAUI tx = " & print_hex_long(txd) & "  (4)";
            state <= Word5;
          when Word5 =>
            debug_state <= "1011";
            txd := data_word(47 downto 0) &
                   not std_logic_vector(udp_cksum(7 downto 0)) &
                   not std_logic_vector(udp_cksum(15 downto 8));
            dout <= txd;
            cout <= x"00";
            data_word <= buffer_data;   -- Latche the data word
            buffer_rden <= '1';         -- Advance the read pointer on the next cycle
            report "XAUI tx = " & print_hex_long(txd) & "  (5)";
            state <= SendData;
          when SendData =>
            debug_state <= "1100";
            data_word <= buffer_data;
            if ( count /= 2 and count /= 1 and count /= 0 ) then
              buffer_rden <= '1';
            else
              buffer_rden <= '0';
            end if;
            if ( count /= 0 ) then
              count <= count - 1;
              txd := buffer_data(47 downto 0) & data_word(63 downto 48);
              cout <= x"00";
              report "Pulled word " & integer'image(to_integer(count));
              report "XAUI tx = " & print_hex_long(txd) & "  (6)";
              state <= SendData;
            else
              txd := x"07fd00000000" & data_word(63 downto 48);
              cout <= x"fc";
              report "XAUI tx = " & print_hex_long(txd) & "  (FCS)";
              state <= FrameCheckSum;
            end if;
            dout <= txd;
          when FrameCheckSum =>
            debug_state <= "1101";
            buffer_rden <= '0';
            txd := x"0707070707070707";
            dout <= txd;
            cout <= x"ff";
            fcs <= '1';
            report "XAUI tx = " & print_hex_long(txd) & "  (7)";
            state <= FinallyDone;
          when FinallyDone =>
            debug_state <= "1110";
            txd := x"0707070707070707";
            dout <= txd;
            cout <= x"ff";
            fcs <= '0';
            issue_arp_request <= '0';
            arptab_read <= '0';
            buffer_rden <= '0';
            report "XAUI tx = " & print_hex_long(txd) & "  (8)";
            done <= '1';
            state <= InterFrameGap0;
          when InterFrameGap0 =>
            debug_state <= "1111";
            txd := x"0707070707070707";
            dout <= txd;
            cout <= x"ff";
            fcs <= '0';
            issue_arp_request <= '0';
            arptab_read <= '0';
            buffer_rden <= '0';
            report "XAUI tx = " & print_hex_long(txd) & "  (IFG 1)";
            state <= InterFrameGap1;
          when InterFrameGap1 =>
            debug_state <= "0000";
            txd := x"0707070707070707";
            dout <= txd;
            cout <= x"ff";
            fcs <= '0';
            issue_arp_request <= '0';
            arptab_read <= '0';
            buffer_rden <= '0';
            report "XAUI tx = " & print_hex_long(txd) & "  (IFG 2)";
            done <= '0';
            state <= Idle;
        end case;
      end if;
    end if;
  end process;

  arptab_lookup_ip <= dst_ip_r;
  busy <= '0' when state = Idle else '1';

end RTL;
