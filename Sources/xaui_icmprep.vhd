--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    12:34:00 10/04/2016 
-- Design Name:    amc502
-- Module Name:    xaui_icmprep - RTL
-- Project Name:   
-- Target Devices: Kintex-7 family
-- Tool versions:  Vivado 2016.1
-- Description:    Sends ICMP reply packet
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

entity xaui_icmprep is
  port (
    reset : in std_logic;
    clk : in std_logic;
    strobe : in std_logic;
    src_ha : in std_logic_vector(47 downto 0);
    src_ip : in std_logic_vector(31 downto 0);
    target_ha : in std_logic_vector(47 downto 0);
    dst_ip : in std_logic_vector(31 downto 0);
    ip_length : in std_logic_vector(15 downto 0);
    icmp_data_we : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(63 downto 0);
    cout : out std_logic_vector(7 downto 0);
    request : out std_logic;
    grant : in std_logic
  );
end xaui_icmprep;

architecture RTL of xaui_icmprep is

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

  type icmp_dram_t is array(0 to 255) of std_logic_vector(63 downto 0);
  signal icmp_dram : icmp_dram_t := ( others => ( others => '0' ) );
  type icmp_cram_t is array(0 to 255) of std_logic_vector(7 downto 0);
  signal icmp_cram : icmp_cram_t := ( others => ( others => '0' ) );

  signal waddr : std_logic_vector(7 downto 0);
  signal raddr : std_logic_vector(7 downto 0);
  signal waddr_en : std_logic := '0';
  signal raddr_en : std_logic := '0';
  signal waddr_clr : std_logic := '0';
  signal raddr_clr : std_logic := '0';
  signal read_dram : std_logic_vector(63 downto 0);
  signal read_cram : std_logic_vector(7 downto 0);

  signal src_ha_r : std_logic_vector(47 downto 0);
  signal src_ip_r : std_logic_vector(31 downto 0);
  signal dst_ha_r : std_logic_vector(47 downto 0);
  signal dst_ip_r : std_logic_vector(31 downto 0);

  signal fcs : std_logic;
  signal last_strobe : std_logic;
  type state_t is ( Idle, RequestAccess, Preamble,
                    Word0, Word1, Word2, Word3, Word4, SendData,
                    FrameCheckSum0, FrameCheckSum1,
                    FrameCheckSum2, FrameCheckSum3,
                    FrameCheckSum4, FrameCheckSum5,
                    FrameCheckSum6, FrameCheckSum7,
                    FrameCheckSum6a, FrameCheckSum7a,
                    Done );
  signal state : state_t;
  signal total_length : unsigned(15 downto 0);
  signal ipheader_cksum : std_logic_vector(15 downto 0);
  signal dst_ha : std_logic_vector(47 downto 0);

begin

--
--  Infer dual port RAMs
--
  process ( clk ) begin
    if ( clk'event and clk = '1' ) then
      read_dram <= icmp_dram(to_integer(unsigned(raddr)));
      if ( icmp_data_we = '1' ) then
        icmp_dram(to_integer(unsigned(waddr))) <= din;
      end if;
    end if;
  end process;

  process ( clk ) begin
    if ( clk'event and clk = '1' ) then
      read_cram <= icmp_cram(to_integer(unsigned(raddr)));
      if ( icmp_data_we = '1' ) then
        icmp_cram(to_integer(unsigned(waddr))) <= cin;
      end if;
    end if;
  end process;

  process ( clk ) begin
    if ( clk'event and clk = '1' ) then
      if ( raddr_clr = '1' ) then
        raddr <= ( others => '0' );
      elsif ( raddr_en = '1' ) then
        raddr <= std_logic_vector(unsigned(raddr)+1);
      end if;
      if ( waddr_clr = '1' ) then
        waddr <= ( others => '0' );
      elsif ( waddr_en = '1' ) then
        waddr <= std_logic_vector(unsigned(waddr)+1);
      end if;
    end if;
  end process;

  process ( clk, reset )
    variable new_hdr_sum : std_logic_vector(15 downto 0);
    variable new_icmp_cksum : unsigned(15 downto 0);
    variable old_icmp_cksum : std_logic_vector(15 downto 0);
  begin
    if ( clk'event and clk = '1' ) then     -- data is valid on the rising edge
      if ( reset = '1' ) then
        dout <= x"0707070707070707";
        cout <= x"ff";
        fcs <= '0';
        request <= '0';
        waddr_en <= '0';
        raddr_clr <= '1';
        raddr_en <= '0';
        state <= Idle;
      else
        case state is
        when Idle =>
          if ( strobe = '1' and last_strobe = '0' ) then
            request <= '1';
            dout <= x"0707070707070707";
            cout <= x"ff";
            fcs <= '0';
            waddr_en <= '0';
            raddr_clr <= '1';
            raddr_en <= '0';
            dst_ha_r <= target_ha;
            src_ip_r <= src_ip;
            src_ha_r <= src_ha;
            dst_ip_r <= dst_ip;
            total_length <= unsigned(ip_length);
            state <= RequestAccess;
          else
            request <= '0';
            dout <= x"0707070707070707";
            cout <= x"ff";
            fcs <= '0';
            state <= Idle;
          end if;
        when RequestAccess =>
          request <= '1';
          if ( grant = '1' ) then
            state <= Preamble;
          else
            state <= RequestAccess;
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
          raddr_clr <= '0';
          state <= Word2;
        when Word2 =>
          dout <= x"014000400000" &
                    std_logic_vector(total_length(7 downto 0)) &
                    std_logic_vector(total_length(15 downto 8));
          cout <= x"00";
          total_length <= total_length - 16;
          raddr_en <= '1';
          state <= Word3;
        when Word3 =>
          dout <= dst_ip_r(23 downto 16) & dst_ip_r(31 downto 24) &
                  src_ip_r(7 downto 0) & src_ip_r(15 downto 8) &
                  src_ip_r(23 downto 16) & src_ip_r(31 downto 24) &
                  not std_logic_vector(ipheader_cksum(7 downto 0)) &
                  not std_logic_vector(ipheader_cksum(15 downto 8));
          cout <= x"00";
          total_length <= total_length - 8;
          state <= Word4;
        when Word4 =>
          total_length <= total_length - 8;
          old_icmp_cksum := read_dram(39 downto 32) & read_dram(47 downto 40);
          new_icmp_cksum := unsigned(old_icmp_cksum) + 2048;  -- 0x0800
--
--  This won't work all the time...
--
          dout <= read_dram(63 downto 48) &
                  std_logic_vector(new_icmp_cksum(7 downto 0)) &
                  std_logic_vector(new_icmp_cksum(15 downto 8)) &
                  x"0000" &
                  dst_ip_r(7 downto 0) & dst_ip_r(15 downto 8);
          cout <= x"00";
          state <= SendData;
        when SendData =>
          if ( total_length < 8 ) then
            dout <= read_dram;
            case total_length(2 downto 0) is
            when "000" =>
              cout <= x"c0";
              state <= FrameCheckSum0;
            when "001" =>
              cout <= x"80";
              state <= FrameCheckSum1;
            when "010" =>
              cout <= read_cram;
              state <= FrameCheckSum2;
            when "011" =>
              cout <= read_cram;
              state <= FrameCheckSum3;
            when "100" =>
              cout <= read_cram;
              state <= FrameCheckSum4;
            when "101" =>
              cout <= read_cram;
              state <= FrameCheckSum5;
            when "110" =>
              cout <= read_cram;
              state <= FrameCheckSum6;
            when "111" =>
              cout <= read_cram;
              state <= FrameCheckSum7;
            when others =>
              report "How did we get here?" severity failure;
            end case;
          else
            dout <= read_dram;
            cout <= read_cram;
            total_length <= total_length - 8;
            state <= SendData;
          end if;
        when FrameCheckSum0 =>
          dout <= x"0707070707fd0000";
          cout <= x"ff";
          fcs <= '1';
          state <= Done;
        when FrameCheckSum1 =>
          dout <= x"07070707fd000000";
          cout <= x"ff";
          fcs <= '1';
          state <= Done;
        when FrameCheckSum2 =>
          dout <= x"070707fd00000000";
          cout <= x"ff";
          fcs <= '1';
          state <= Done;
        when FrameCheckSum3 =>
          dout <= x"0707fd00000000" & read_dram(7 downto 0);
          cout <= x"fe";
          fcs <= '1';
          state <= Done;
        when FrameCheckSum4 =>
          dout <= x"07fd00000000" & read_dram(15 downto 0);
          cout <= x"fc";
          fcs <= '1';
          state <= Done;
        when FrameCheckSum5 =>
          dout <= x"fd00000000" & read_dram(23 downto 0);
          cout <= x"f8";
          fcs <= '1';
          state <= Done;
        when FrameCheckSum6 =>
          dout <= x"00000000" & read_dram(31 downto 0);
          cout <= x"f0";
          fcs <= '0';
          state <= FrameCheckSum6a;
        when FrameCheckSum6a =>
          dout <= x"07070707070707fd";
          cout <= x"ff";
          fcs <= '1';
          state <= Done;
        when FrameCheckSum7 =>
          dout <= x"000000" & read_dram(39 downto 0);
          cout <= x"e0";
          fcs <= '0';
          state <= FrameCheckSum7a;
        when FrameCheckSum7a =>
          dout <= x"070707070707fd00";
          cout <= x"ff";
          fcs <= '1';
          state <= Done;
        when Done =>
          dout <= x"0707070707070707";
          cout <= x"ff";
          fcs <= '0';
          raddr_en <= '0';
          state <= Idle;
        end case;
      end if;
      last_strobe <= strobe;
      waddr_en <= icmp_data_we;
    end if;
  end process;
  waddr_clr <= not waddr_en;

end RTL;
