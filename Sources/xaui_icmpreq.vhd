--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    12:34:00 10/04/2016 
-- Design Name:    amc502
-- Module Name:    xaui_icmpreq - RTL
-- Project Name:   
-- Target Devices: Kintex-7 family
-- Tool versions:  Vivado 2016.1
-- Description:    Sends ICMP request packet
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

entity xaui_icmpreq is
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
    sequence : in std_logic_vector(15 downto 0);
    identifier : in std_logic_vector(15 downto 0);
    length : in std_logic_vector(15 downto 0);
    dout : out std_logic_vector(63 downto 0);
    cout : out std_logic_vector(7 downto 0);
    request : out std_logic;
    grant : in std_logic;
    stop : in std_logic;
    timer : out std_logic_vector(31 downto 0)
  );
end xaui_icmpreq;
 
architecture RTL of xaui_icmpreq is

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

  type State_t is ( Idle, RequestAccess,
                    ArptabLookup, DoingArptabLookup, Preamble,
                    Word0, Word1, Word2, Word3, Word4,
                    FrameCheckSum0, FrameCheckSum1,
                    FrameCheckSum2, FrameCheckSum3,
                    FrameCheckSum4, FrameCheckSum5,
                    FrameCheckSum6, FrameCheckSum7,
--                  FrameCheckSum6a, FrameCheckSum7a,
                    SendSequence, SendData, Done );
  signal state : State_t := Idle;
  signal last_strobe : std_logic_vector(2 downto 0);
  signal fcs : std_logic;
  signal ipheader_cksum : std_logic_vector(15 downto 0);
  signal icmp_cksum : std_logic_vector(15 downto 0);
  signal total_length : unsigned(15 downto 0);
  signal nbyte : unsigned(15 downto 0);

  signal src_ha_r : std_logic_vector(47 downto 0);
  signal src_ip_r : std_logic_vector(31 downto 0);
  signal dst_ip_r : std_logic_vector(31 downto 0);
  signal dst_ha_r : std_logic_vector(47 downto 0);
  signal sequence_r : std_logic_vector(15 downto 0);
  signal identifier_r : std_logic_vector(15 downto 0);
  signal counter : unsigned(31 downto 0);
  signal counting : std_logic := '0';

begin

  process ( clk, reset )
    variable new_hdr_sum : std_logic_vector(15 downto 0);
  begin
    if ( clk'event and clk = '1' ) then     -- data is valid on the rising edge
      if ( reset = '1' ) then
        dout <= x"0707070707070707";
        cout <= x"ff";
        request <= '0';
        arptab_read <= '0';
        fcs <= '0';
        state <= Idle;
      else
        case state is
        when Idle =>
          if ( last_strobe(last_strobe'left) = '1' and last_strobe(0) = '0' ) then
            dout <= x"0707070707070707";
            cout <= x"ff";
            src_ha_r <= src_ha;
            src_ip_r <= src_ip;
            dst_ip_r <= dst_ip;
            sequence_r <= sequence;
            identifier_r <= identifier;
            nbyte <= unsigned(length);
            total_length <= unsigned(length)+28;  -- 20 byte IP header + 8 byte ICMP header
            fcs <= '0';
            state <= RequestAccess;
          else
            dout <= x"0707070707070707";
            cout <= x"ff";
            arptab_read <= '0';
            request <= '0';
            fcs <= '0';
            state <= Idle;
          end if;
        when RequestAccess =>
          request <= '1';
          if ( grant = '1' ) then
            arptab_read <= '1';
            state <= ArptabLookup;
          else
            state <= RequestAccess;
          end if;
        when ArptabLookup =>
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
          ipheader_cksum <= add_cksum(x"c501",std_logic_vector(total_length));
          dout <= x"d5555555555555fb";
          cout <= x"01";
          state <= Word0;
        when Word0 =>
          new_hdr_sum := add_cksum(ipheader_cksum,src_ip_r(15 downto 0));
          ipheader_cksum <= add_cksum(new_hdr_sum,src_ip_r(31 downto 16));
          dout <= src_ha_r(39 downto 32) & src_ha_r(47 downto 40) &
                  dst_ha_r(7 downto 0) & dst_ha_r(15 downto 8) &
                  dst_ha_r(23 downto 16) & dst_ha_r(31 downto 24) &
                  dst_ha_r(39 downto 32) & dst_ha_r(47 downto 40);
          cout <= x"00";
          state <= Word1;
        when Word1 =>
          new_hdr_sum := add_cksum(ipheader_cksum,dst_ip_r(15 downto 0));
          ipheader_cksum <= add_cksum(new_hdr_sum,dst_ip_r(31 downto 16));
          dout <= x"00450008" &
                  src_ha_r(7 downto 0) & src_ha_r(15 downto 8) &
                  src_ha_r(23 downto 16) & src_ha_r(31 downto 24);
          cout <= x"00";
          state <= Word2;
        when Word2 =>
          icmp_cksum <= add_cksum(sequence_r,identifier_r);
          dout <= x"014000400000" &
                    std_logic_vector(total_length(7 downto 0)) &
                    std_logic_vector(total_length(15 downto 8));
          cout <= x"00";
          state <= Word3;
        when Word3 =>
          icmp_cksum <= add_cksum(x"0800",icmp_cksum);
          dout <= dst_ip_r(23 downto 16) & dst_ip_r(31 downto 24) &
                  src_ip_r(7 downto 0) & src_ip_r(15 downto 8) &
                  src_ip_r(23 downto 16) & src_ip_r(31 downto 24) &
                  not std_logic_vector(ipheader_cksum(7 downto 0)) &
                  not std_logic_vector(ipheader_cksum(15 downto 8));
          cout <= x"00";
          state <= Word4;
        when Word4 =>
          dout <= identifier_r(7 downto 0) & identifier_r(15 downto 8) &
                  not std_logic_vector(icmp_cksum(7 downto 0)) &
                  not std_logic_vector(icmp_cksum(15 downto 8)) &
                  x"0008" & dst_ip_r(7 downto 0) & dst_ip_r(15 downto 8);
          cout <= x"00";
          state <= SendSequence;
        when SendSequence =>
          dout <= x"000000000000" & sequence_r(7 downto 0) & sequence_r(15 downto 8);
          cout <= x"00";
          nbyte <= nbyte - 8;
          state <= SendData;
        when SendData =>
          if ( nbyte < 8 ) then
            case nbyte(2 downto 0) is
            when"000" =>
              dout <= x"07fd000000000000";
              cout <= x"fc";
              state <= FrameCheckSum0;
            when "001" =>
              dout <= x"fd00000000000000";
              cout <= x"f8";
              state <= FrameCheckSum1;
            when "010" =>
              dout <= x"0000000000000000";
              cout <= x"f0";
              state <= FrameCheckSum2;
            when "011" =>
              dout <= x"0000000000000000";
              cout <= x"e0";
              state <= FrameCheckSum3;
            when "100" =>
              dout <= x"0000000000000000";
              cout <= x"c0";
              state <= FrameCheckSum4;
            when "101" =>
              dout <= x"0000000000000000";
              cout <= x"80";
              state <= FrameCheckSum5;
            when "110" =>
              dout <= x"0000000000000000";
              cout <= x"00";
              state <= FrameCheckSum6;
            when "111" =>
              dout <= x"0000000000000000";
              cout <= x"00";
              state <= FrameCheckSum7;
            when others =>
              report "How on earth did we get here?" severity failure;
            end case;
          else
            dout <= x"0000000000000000";
            cout <= x"00";
            nbyte <= nbyte - 8;
            state <= SendData;         
          end if;
        when FrameCheckSum0 =>
          dout <= x"0707070707070707";
          cout <= x"ff";
          fcs <= '1';
          state <= Done;
        when FrameCheckSum1 =>
          dout <= x"0707070707070707";
          cout <= x"ff";
          fcs <= '1';
          state <= Done;
        when FrameCheckSum2 =>
          dout <= x"07070707070707fd";
          cout <= x"ff";
          fcs <= '1';
          state <= Done;
        when FrameCheckSum3 =>
          dout <= x"070700707707fd00";
          cout <= x"fe";
          fcs <= '1';
          state <= Done;
        when FrameCheckSum4 =>
          dout <= x"0707070707fd0000";
          cout <= x"fc";
          fcs <= '1';
          state <= Done;
        when FrameCheckSum5 =>
          dout <= x"07070707fd000000";
          cout <= x"f8";
          fcs <= '1';
          state <= Done;
        when FrameCheckSum6 =>
          dout <= x"070707fd00000000";
          cout <= x"ff";
          fcs <= '1';
          state <= Done;
--        when FrameCheckSum6a =>
--          dout <= x"0707070707070707";
--          cout <= x"ff";
--          fcs <= '0';
--          state <= Done;
        when FrameCheckSum7 =>
          dout <= x"0707fd0000000000";
          cout <= x"fe";
          fcs <= '1';
          state <= Done;
--        when FrameCheckSum7a =>
--          dout <= x"0707070707070707";
--          cout <= x"ff";
--          fcs <= '0';
--          state <= Done;
        when Done =>
          dout <= x"0707070707070707";
          cout <= x"ff";
          fcs <= '0';
          if ( strobe = '0' ) then
            state <= Idle;
          end if;
        end case;
      end if;
      last_strobe <= strobe & last_strobe(last_strobe'left downto 1);
    end if;
  end process;

  process ( clk, reset ) begin
    if ( clk'event and clk = '1' ) then
      if ( reset = '1' ) then
        timer <= ( others => '0' );
        counter <= ( others => '0' );
        counting <= '0';
      else
        if ( counting = '0' ) then
          if ( fcs = '1' ) then
            counter <= ( others => '0' );
            counting <= '1';
          end if;
        else
          if ( stop = '1' ) then
            counting <= '0';
            timer <= std_logic_vector(counter);
          elsif ( counter(counter'left) = '1' ) then
            counting <= '0';
            timer <= ( others => '1' );
          else
            counter <= counter + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  arptab_lookup_ip <= dst_ip_r;

end RTL;
