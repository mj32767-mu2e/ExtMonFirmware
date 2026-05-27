--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    5/31/2013 
-- Design Name:    mu2e_amc502
-- Module Name:    ethernet - RTL
-- Project Name:   Mu2e
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Parses Ethernet frames
--
-- Dependencies:   crc
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity ethernet is
  port ( reset : in std_logic;    -- synchronous reset
         clk : in std_logic;      -- GMII clock - data valid on rising edge
         enable : in std_logic;
         din : in std_logic_vector(7 downto 0);
         saddr : out std_logic_vector(47 downto 0);
         daddr : out std_logic_vector(47 downto 0);
         frame_type : out std_logic_vector(15 downto 0);
         arp_enable : out std_logic;
         ip_enable : out std_logic;
         payload : out std_logic;
         frame_strobe : out std_logic;
         crc_valid : out std_logic
       );
end ethernet;

architecture rtl of ethernet is

  type state_t is ( Idle,
                    Preamble,
                    Start_of_frame,
                    Invalid,
                    Dest_hwaddr0,
                    Dest_hwaddr1,
                    Dest_hwaddr2,
                    Dest_hwaddr3,
                    Dest_hwaddr4,
                    Dest_hwaddr5,
                    Src_hwaddr0,
                    Src_hwaddr1,
                    Src_hwaddr2,
                    Src_hwaddr3,
                    Src_hwaddr4,
                    Src_hwaddr5,
                    Ether_type0,
                    Ether_type1,
                    Frame,
                    End_of_frame
                  );

  signal state : state_t := Idle;
  signal clear_crc : std_logic := '0';
  signal do_crc : std_logic := '0';
  signal calc_crc : std_logic := '0';
  signal valid_crc : std_logic := '0';
  signal ether_type : std_logic_vector(15 downto 0);
  signal src_hwaddr : std_logic_vector(47 downto 0);
  signal dst_hwaddr : std_logic_vector(47 downto 0);
  signal crc_byte : std_logic_vector(7 downto 0);
  signal crc_reg : std_logic_vector(31 downto 0);
 
  signal receiving_payload : std_logic;
  signal matched_type_high : std_logic;
  signal match_ip_type_low : std_logic;
  signal match_arp_type_low : std_logic;

  component crc32 is
    port (
      clock : in std_logic;
      clear : in std_logic;
      data : in std_logic_vector(7 downto 0);
      calc : in std_logic;
      crc_byte : out std_logic_vector(7 downto 0);
      crc_reg : out std_logic_vector(31 downto 0);
      valid : out std_logic
    );
  end component;

begin

  crc32_imp : crc32
  port map (
    clock => clk,
    data => din,
    clear => clear_crc,
    calc => calc_crc,
    crc_byte => crc_byte,
    crc_reg => crc_reg,
    valid => valid_crc 
  );

  process ( clk, reset, enable ) begin
    if ( clk'event and clk = '1' ) then  -- registered data is valid on the rising clock edge
      if ( reset = '1' ) then
        state <= Idle;
        src_hwaddr <= x"000000000000";
        dst_hwaddr <= x"000000000000";
        ether_type <= x"0000";
        receiving_payload <= '0';
        ip_enable <= '0';
        arp_enable <= '0';
        matched_type_high <= '0';
      elsif ( enable = '1' ) then
        case state is
          when Idle =>
            src_hwaddr <= X"000000000000";
            dst_hwaddr <= X"000000000000";
            ether_type <= X"0000";
            clear_crc <= '1';
            do_crc <= '0';
            crc_valid <= '0';
            frame_strobe <= '0';
            receiving_payload <= '0';
            ip_enable <= '0';
            arp_enable <= '0';
            matched_type_high <= '0';
            if ( din = X"55" ) then
              state <= Preamble;
            end if;
          when Preamble =>
            if ( din = x"55" ) then
              clear_crc <= '1';
            elsif ( din = x"d5" ) then
              clear_crc <= '0';
              do_crc <= '1';
              state <= Start_of_frame;
            else
              state <= Invalid;
            end if;
          when Start_of_frame =>
            dst_hwaddr(47 downto 40) <= din;
            state <= Dest_hwaddr0;
          when Dest_hwaddr0 =>
            dst_hwaddr(39 downto 32) <= din;
            state <= Dest_hwaddr1;
          when Dest_hwaddr1 =>
            dst_hwaddr(31 downto 24) <= din;
            state <= Dest_hwaddr2;
          when Dest_hwaddr2 =>
            dst_hwaddr(23 downto 16) <= din;
            state <= Dest_hwaddr3;
          when Dest_hwaddr3 =>
            dst_hwaddr(15 downto 8) <= din;
            state <= Dest_hwaddr4;
          when Dest_hwaddr4 =>
            dst_hwaddr(7 downto 0) <= din;
            state <= Dest_hwaddr5;
          when Dest_hwaddr5 =>
            daddr <= Dst_hwaddr;
            src_hwaddr(47 downto 40) <= din;
            state <= Src_hwaddr0;
          when Src_hwaddr0 =>
            src_hwaddr(39 downto 32) <= din;
            state <= Src_hwaddr1;
          when Src_hwaddr1 =>
            src_hwaddr(31 downto 24) <= din;
            state <= Src_hwaddr2;
          when Src_hwaddr2 =>
            src_hwaddr(23 downto 16) <= din;
            state <= Src_hwaddr3;
          when Src_hwaddr3 =>
            src_hwaddr(15 downto 8) <= din;
            state <= Src_hwaddr4;
          when Src_hwaddr4 =>
            src_hwaddr(7 downto 0) <= din;
            state <= Src_hwaddr5;
          when Src_hwaddr5 =>
            saddr <= Src_hwaddr;
            ether_type(15 downto 8) <= din;
            if ( din = x"08" ) then
              matched_type_high <= '1';     -- Match high byte of ethertype word.
            end if;
            state <= Ether_type0;
          when Ether_type0 =>
            ether_type(7 downto 0) <= din;
            frame_type <= ether_type(15 downto 8) & din;
            ip_enable <= match_ip_type_low;
            arp_enable <= match_arp_type_low;
            state <= Ether_type1;
            receiving_payload <= '1';
          when Ether_type1 =>
            state <= Frame;
          when others =>
        end case;
      else
        case state is
          when Frame =>
            frame_strobe <= '1';
            crc_valid <= valid_crc;
            state <= End_of_frame;
          when others =>
            frame_strobe <= '0';
            state <= Idle;
        end case;
      end if;
    end if;
  end process;

  calc_crc <= enable and do_crc;
  payload <= enable and receiving_payload;
  match_ip_type_low <= matched_type_high when ( din = x"00" ) else '0';
  match_arp_type_low <= matched_type_high when ( din = x"06" ) else '0';

end rtl;
