----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/24/2018 13:10:13
-- Design Name: 
-- Module Name: latch_generator - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description:   This generates latch commands either individually or
--                continuously.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity latch_generator is
port (
  bcoclk : in std_logic;
  strobe : in std_logic;
  busy : out std_logic;
  period : in std_logic_vector(15 downto 0);
  count : in std_logic_vector(7 downto 0);
  latch : out std_logic
);
end latch_generator;

architecture Behavioral of latch_generator is

  type state_t is ( Idle, SendLatch, WaitPeriod, Finished, Continuous );
  signal state : state_t;
  signal latched_strobe : std_logic;
  signal latched_count : std_logic_vector(7 downto 0);
  signal latched_period : std_logic_vector(15 downto 0);
  signal counter : unsigned(7 downto 0);
  signal bco_counter : unsigned(15 downto 0);
begin

  process ( bcoclk ) begin
    if ( bcoclk'event and bcoclk = '1' ) then
      latched_strobe <= strobe;
      latched_count <= count;
      latched_period <= period;
      case state is
      when Idle =>
        latch <= '0';
        if ( latched_strobe = '1' ) then
          busy <= '1';
          if ( latched_count = x"00" ) then
            state <= Continuous;
          else
            counter <= unsigned(latched_count);
            state <= SendLatch;
          end if;
        else
          busy <= '0';
        end if;
      when SendLatch =>
        bco_counter <= x"0002";
        latch <= '1';
        if ( counter /= x"00" ) then
          counter <= counter - 1;
          state <= WaitPeriod;
        else
          state <= Finished;
        end if;
      when WaitPeriod =>
        latch <= '0';
        if ( std_logic_vector(bco_counter) = latched_period ) then
          state <= SendLatch;
        else
          bco_counter <= bco_counter + 1;
        end if;
      when Finished =>
        latch <= '0';
        if ( strobe = '0' ) then
          state <= Idle;
        end if;
      when Continuous =>
        if ( std_logic_vector(bco_counter) = latched_period ) then
          latch <= '1';
          bco_counter <= ( others => '0' );
          if ( latched_strobe = '0' ) then
            state <= Idle;
          end if;
        else
          latch <= '0';
          bco_counter <= bco_counter + 1;
          state <= Continuous;
        end if;
      end case;
    end if;
  end process;

end Behavioral;
