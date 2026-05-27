--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    08:44:16 06/06/2013 
-- Design Name:    stib
-- Module Name:    ipheader - RTL
-- Project Name:   STIB firmware
-- Target Devices: xc4vlx25ff668-10
-- Tool versions:  ISE 14.4 / 14.6
-- Description:    Parses IP packet headers
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
use IEEE.NUMERIC_STD.ALL;

entity ipheader is
  port (
    reset : in std_logic;
    clk : in std_logic;
    strobe : in std_logic;
    length : in std_logic_vector(15 downto 0);
    protocol : in std_logic_vector(7 downto 0);
    saddr : in std_logic_vector(31 downto 0);
    daddr : in std_logic_vector(31 downto 0);
    dout : out std_logic_vector(7 downto 0);
    checksum : out std_logic_vector(15 downto 0)
  );
end ipheader;

architecture RTL of ipheader is
  type state_t is ( Idle,
                    Ethertype0, Ethertype1, Word0, Word1, Length0, Length1,
                    Ident0, Ident1, Flags, Frag,
                    Time_to_live, Proto, Checksum0, Checksum1,
                    Saddr0, Saddr1, Saddr2, Saddr3,
                    Daddr0, Daddr1, Daddr2, Daddr3,
                    Done
                  );
  signal state : state_t := Idle;
  signal cksum : std_logic_vector(15 downto 0);
  signal cksum_input : std_logic_vector(15 downto 0);
  signal carry_high : std_logic;
  signal carry_low : std_logic;
  signal cksum_enable : std_logic;
  signal cksum_clear : std_logic;

  component add8
  port (
    a : in std_logic_vector(7 downto 0);
    b : in std_logic_vector(7 downto 0);
    clk : in std_logic;
    c_in : in std_logic;
    ce : in std_logic;
    sclr : in std_logic;
    c_out : out std_logic;
    s : out std_logic_vector(7 downto 0)
  );
  end component;

begin

  sum_low : add8
  port map (
    a => cksum_input(7 downto 0),
    b => cksum(7 downto 0),
    s => cksum(7 downto 0),
    clk => clk,
    ce => cksum_enable,
    sclr => cksum_clear,
    c_out => carry_low,
    c_in => carry_high
  );
  sum_high : add8
  port map (
    a => cksum_input(15 downto 8),
    b => cksum(15 downto 8),
    s => cksum(15 downto 8),
    clk => clk,
    ce => cksum_enable,
    sclr => cksum_clear,
    c_out => carry_high,
    c_in => carry_low
  );

  process ( clk, strobe, reset ) begin
    if ( clk'event and clk = '1' ) then
      if ( reset = '1' ) then
        dout <= x"77";
        cksum_clear <= '1';
        cksum_enable <= '0';
        state <= Idle;
      else
        case state is
          when Idle =>
            dout <= x"08";
            if ( strobe = '1' ) then
              dout <= x"00";
              cksum_clear <= '0';
              cksum_enable <= '1';
              cksum_input <= x"4500";  -- version, etc
              state <= Ethertype1;
            end if;
          when Ethertype1 =>
            dout <= x"45";
            cksum_input <= length;   -- length
            state <= Word0;
          when Word0 =>
            dout <= x"00";
            cksum_input <= x"0000";  -- identification
            state <= word1;
          when Word1 =>
            dout <= length(15 downto 8);
            cksum_input <= x"4000";  -- flags & frags
            state <= Length0;
          when Length0 =>
            dout <= length(7 downto 0);
            cksum_input <= x"40" & protocol;  -- time to live & protocol
            state <= Length1;
          when Length1 =>
            dout <= x"00";
            cksum_input <= saddr(31 downto 16);
            state <= Ident0;
          when Ident0 =>
            dout <= x"00";
            cksum_input <= saddr(15 downto 0);
            state <= Ident1;
          when Ident1 =>
            dout <= x"40";
            cksum_input <= daddr(31 downto 16);
            state <= Flags;
          when Flags =>
            dout <= x"00";
            cksum_input <= daddr(15 downto 0);
            state <= Frag;
          when Frag =>
            dout <= x"40";
            cksum_input <= x"0000";
            state <= Time_to_live;
          when Time_to_live =>
            dout <= protocol;
            state <= Proto;
          when Proto =>
            cksum_enable <= '0';
            checksum <= cksum;
            dout <= not cksum(15 downto 8);
            state <= Checksum0;
          when Checksum0 =>
            dout <= not cksum(7 downto 0);
            state <= Checksum1;
          when Checksum1 =>
            dout <= saddr(31 downto 24);
            state <= Saddr0;
          when Saddr0 =>
            dout <= saddr(23 downto 16);
            state <= Saddr1;
          when Saddr1 =>
            dout <= saddr(15 downto 8);
            state <= Saddr2;
          when Saddr2 =>
            dout <= saddr(7 downto 0);
            state <= Saddr3;
          when Saddr3 =>
            dout <= daddr(31 downto 24);
            state <= Daddr0;
          when Daddr0 =>
            dout <= daddr(23 downto 16);
            state <= Daddr1;
          when Daddr1 =>
            dout <= daddr(15 downto 8);
            state <= Daddr2;
          when Daddr2 =>
            dout <= daddr(7 downto 0);
            state <= Daddr3;
          when Daddr3 =>
            cksum_clear <= '1';
            state <= Done;
          when others =>
            if ( strobe = '0' ) then
              state <= Idle;
            end if;
        end case;
      end if;
    end if;
  end process;

end RTL;
