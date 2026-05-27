--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    2-Oct-2016
-- Design Name:    mu2e_amc502
-- Module Name:    xaui_ethernet - RTL
-- Project Name:   Mu2e
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Parses 10GbE XAUI frames
--
-- Dependencies:   crc
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xaui_ethernet is
  port ( reset : in std_logic;
         clk : in std_logic;
         enable : in std_logic;
         din : in std_logic_vector(63 downto 0);
         cin : in std_logic_vector(7 downto 0);
         my_hw_addr : in std_logic_vector(47 downto 0);
         saddr : out std_logic_vector(47 downto 0);
         daddr : out std_logic_vector(47 downto 0);
         src_ip : out std_logic_vector(31 downto 0);
         dst_ip : out std_logic_vector(31 downto 0);
         crc_valid : out std_logic;
         arp_enable : out std_logic;
         icmp_enable : out std_logic;
         udp_enable : out std_logic;
         ip_length : out std_logic_vector(15 downto 0)
       );
end xaui_ethernet;

architecture rtl of xaui_ethernet is

  component crc32x64_slice
  port (
    clk : in std_logic;
    en : in std_logic;
    clr : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(31 downto 0);
    valid : out std_logic
  );
  end component;

  component crc32x64_table
  port (
    clk : in std_logic;
    en : in std_logic;
    clr : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(31 downto 0);
    valid : out std_logic
  );
  end component;

  component crc32x64rom
  port (
    clk : in std_logic;
    en : in std_logic;
    clr : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(31 downto 0);
    valid : out std_logic
  );
  end component;

  component crc32x64
  port (
    clk : in std_logic;
    en : in std_logic;
    clr : in std_logic;
    din : in std_logic_vector(63 downto 0);
    cin : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(31 downto 0);
    valid : out std_logic
  );
  end component;

  type state_t is ( Word1, Word2, ArpFrame, IpFrame0, IpFrame1, IpFrame2, EndFrame );
  signal state : state_t := Word1;
  signal src_hwaddr : std_logic_vector(47 downto 0);
  signal dst_hwaddr : std_logic_vector(47 downto 0);
  signal match_hw_addr : std_logic;
  signal arp : std_logic;
  signal icmp : std_logic;
  signal udp : std_logic;
  signal crc_en : std_logic;
  signal crc_clr : std_logic;
  signal valid : std_logic;
  signal crc : std_logic_vector(31 downto 0);

  attribute mark_debug : string;
  attribute dont_touch : string;
  attribute mark_debug of crc : signal is "true";
  attribute dont_touch of crc : signal is "true";
  attribute mark_debug of valid : signal is "true";
  attribute dont_touch of valid : signal is "true";

begin

  crc_imp : crc32x64_slice
  port map (
    clk => clk,
    en => crc_en,
    clr => crc_clr,
    din => din,
    cin => cin,
    dout => crc,
    valid => valid
  );

  process ( clk, reset, enable ) begin
    if ( clk'event and clk = '1' ) then  -- registered data is valid on the rising clock edge
      if ( reset = '1' ) then
        state <= Word1;
        src_hwaddr <= x"000000000000";
        dst_hwaddr <= x"000000000000";
        udp <= '0';
        arp <= '0';
        icmp <= '0';
      else
        case state is
        when Word1 =>
          src_hwaddr <= X"000000000000";
          dst_hwaddr <= X"000000000000";
          udp <= '0';
          arp <= '0';
          icmp <= '0';
          if ( enable = '1' ) then
            dst_hwaddr(47 downto 40) <= din(7 downto 0);
            dst_hwaddr(39 downto 32) <= din(15 downto 8);
            dst_hwaddr(31 downto 24) <= din(23 downto 16);
            dst_hwaddr(23 downto 16) <= din(31 downto 24);
            dst_hwaddr(15 downto 8) <= din(39 downto 32);
            dst_hwaddr(7 downto 0) <= din(47 downto 40);
            src_hwaddr(47 downto 40) <= din(55 downto 48);
            src_hwaddr(39 downto 32) <= din(63 downto 56);
            state <= Word2;
          else
            state <= Word1;
          end if;
        when Word2 =>
          src_hwaddr(31 downto 24) <= din(7 downto 0);
          src_hwaddr(23 downto 16) <= din(15 downto 8);
          src_hwaddr(15 downto 8) <= din(23 downto 16);
          src_hwaddr(7 downto 0) <= din(31 downto 24);
          if ( match_hw_addr = '1' and din(39 downto 32 ) = x"08" ) then
            if ( din(47 downto 40) = x"06" ) then
              arp <= '1';
              icmp <= '0';
              udp <= '0';
              state <= EndFrame;
            elsif ( din(47 downto 40) = x"00" ) then
              arp <= '0';
              icmp <= '0';
              udp <= '0';
              state <= IpFrame0;
            end if;
          else
            arp <= '0';
            icmp <= '0';
            udp <= '0';
            state <= ArpFrame;
          end if;
        when ArpFrame =>
          arp <= '1';
          icmp <= '0';
          udp <= '0';
          state <= EndFrame;
        when IpFrame0 =>
          ip_length(7 downto 0) <= din(15 downto 8);
          ip_length(15 downto 8) <= din(7 downto 0);
          if ( din(63 downto 56) = x"11" ) then
            arp <= '0';
            icmp <= '0';
            udp <= '1';
            state <= IpFrame1;
          elsif ( din(63 downto 56) = x"01" ) then
            arp <= '0';
            icmp <= '1';
            udp <= '0';
            state <= IpFrame1;
          else
            arp <= '0';
            udp <= '0';
            icmp <= '0';
            state <= EndFrame;
          end if;
        when IpFrame1 =>
          src_ip(31 downto 24) <= din(23 downto 16);
          src_ip(23 downto 16) <= din(31 downto 24);
          src_ip(15 downto 8) <= din(39 downto 32);
          src_ip(7 downto 0) <= din(47 downto 40);
          dst_ip(31 downto 24) <= din(55 downto 48);
          dst_ip(23 downto 16) <= din(63 downto 56);
          state <= IpFrame2;
        when IpFrame2 =>
          dst_ip(15 downto 8) <= din(7 downto 0);
          dst_ip(7 downto 0) <= din(15 downto 8);
          state <= EndFrame;
        when EndFrame =>
          if ( enable = '0' ) then
            arp <= '0';
            icmp <= '0';
            udp <= '0';
            state <= Word1;
          else
            state <= EndFrame;
          end if;
        end case;
      end if;
    end if;
  end process;

  crc_en <= enable;
  crc_clr <= not enable;
  crc_valid <= valid;

  match_hw_addr <= '1' when dst_hwaddr = x"ffffffffffff" else
                   '1' when dst_hwaddr = my_hw_addr else '0';
  saddr <= src_hwaddr;
  daddr <= dst_hwaddr;
  arp_enable <= enable when arp = '1' else '0';
  icmp_enable <= enable when icmp = '1' else '0';
  udp_enable <= enable when udp = '1' else '0';

end rtl;
