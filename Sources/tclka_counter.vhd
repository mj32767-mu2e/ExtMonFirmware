--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    05:13:38 12/03/2018 
-- Design Name:    amc502
-- Module Name:    tclka_counter - Behavioral
-- Project Name:   AMC502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2017.3
-- Description:    This counts commands received on the clock bus
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

library unisim;
use unisim.vcomponents.all;
library unimacro;
use unimacro.vcomponents.all;

entity tclka_counter is
  port (
    clk : in std_logic;
    strobe : in std_logic_vector(15 downto 0);
    stop : in std_logic;
    sel : in std_logic_vector(3 downto 0);
    count : out std_logic_vector(47 downto 0);
    timer : out std_logic_vector(47 downto 0);
    timeout : in std_logic_vector(47 downto 0);
    alarm : out std_logic;
    reset : in std_logic;
    busy : out std_logic
  );
end tclka_counter;

architecture Behavioral of tclka_counter is

  type counter_array_t is array(15 downto 0) of std_logic_vector(47 downto 0);
  signal counter_array : counter_array_t;
  signal timer_count : std_logic_vector(47 downto 0);
  signal start_time : std_logic_vector(47 downto 0);
  signal stop_time : std_logic_vector(47 downto 0);
  signal timer_time : std_logic_vector(47 downto 0);
  signal timer_r : std_logic_vector(47 downto 0);
  signal ceo : std_logic_vector(15 downto 0);
  signal rst : std_logic := '0';
  signal stop_r : std_logic;
  signal r_reset : std_logic;
  signal counter_select : std_logic_vector(3 downto 0);
  signal enable : std_logic_vector(15 downto 0);
  signal mask : std_logic_vector(15 downto 0) := ( others => '1' );
  type state_t is ( idle, resetting, done, tick );
  signal timer_running : std_logic := '0';
  signal timer_expired : std_logic := '0';
  signal state : state_t := idle;

begin

  g : for i in 0 to 15 generate
    count_imp : counter_tc_macro
    generic map (
      device => "7SERIES",
      direction => "UP",
      reset_upon_tc => "TRUE",
      width_data => 48
    )
    port map (
      clk => clk,
      ce => enable(i),
      q => counter_array(i),
      rst => rst,
      tc => open
    );
  end generate;

  timer_imp : counter_tc_macro
  generic map (
    device => "7SERIES",
    direction => "UP",
    reset_upon_tc => "TRUE",
    width_data => 48
  )
  port map (
    clk => clk,
    ce => timer_running,
    q => timer_count,
    rst => rst,
    tc => open
  );

--  compare_imp : eq_compare_macro
--  generic map (
--    device => "7SERIES",
--    sel_mask => "DYNAMIC_PATTERN"
--  )
--  port map (
--    q => timer_expired,
--    data_in => timer_time,
--    dynamic_pattern => timeout,
--    clk => clk,
--    ce => timer_running,
--    rst => rst
--  );

  process ( clk ) begin
    if ( clk'event and clk = '1' ) then
      r_reset <= reset;
      stop_r <= stop;
      counter_select <= sel;
      stop_time <= timer_count;
      timer_r <= timer_time;
      if ( unsigned(timer_r) > unsigned(timeout) ) then
        alarm <= timer_running;
      else
        alarm <= '0';
      end if;
      case state is
      when idle =>
        if ( strobe(13) = '1' ) then   -- process halt
          mask <= "0010001000000000";
        end if;
        if ( strobe(8) = '1' ) then   -- process run
          mask <= ( others => '1' );
        end if;
        if ( strobe(10) = '1' ) then  -- process start
          start_time <= timer_count;
          timer_running <= '1';
        end if;
        if ( strobe(11) = '1' or stop_r = '1' ) then  -- process stop
          timer_running <= '0';
        end if;
        if ( r_reset = '1' and rst = '0' ) then
          state <= resetting;
        end if;
      when resetting =>
        if ( rst = '1' and r_reset = '0' ) then
          state <= done;
        end if;
      when done =>
        state <= tick;
      when tick =>
        state <= idle;
      end case;
    end if;
  end process;

  rst <= '1' when state = resetting else '0';
  enable <= strobe and mask when state = idle else ( others => '1' ) when state = tick else ( others => '0' );
  count <= counter_array(to_integer(unsigned(counter_select))); 
  timer_time <= std_logic_vector(unsigned(stop_time)-unsigned(start_time));
  timer <= timer_time;
  busy <= rst;

end Behavioral;
