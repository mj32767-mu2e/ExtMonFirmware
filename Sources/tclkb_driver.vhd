--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    15:48:38 11/25/2018 
-- Design Name:    amc502
-- Module Name:    tclkb_driver - Behavioral
-- Project Name:   AMC502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    This drives the TCLKA clock line with encoded trigger data
--
-- Dependencies:
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--   The recovered 40 MHz clock and the 80 MHz are aligned on their falling
--   edge.
--               _____       _____       ___
--   bcoclk ____|     |_____|     |_____|
--            __    __    __    __    __
--   sysclk  |  |__|  |__|  |__|  |__|  |__
--
--
-- Changes:
--   14-Nov-2024 - Registered d input
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity tclkb_driver is
  port (
    sysclk : in std_logic;
    bcoclk : in std_logic;
    d : in std_logic_vector(3 downto 0);
    dv : in std_logic;
    d16 : in std_logic_vector(15 downto 0);
    dv16 : in std_logic;
    ack16 : out std_logic;
    tclkb_out : out std_logic
  );
end tclkb_driver;

architecture Behavioral of tclkb_driver is

  signal dv_r : std_logic;
  signal d_r : std_logic_vector(3 downto 0);
  signal dv16_r : std_logic;
  signal busy_r : std_logic;
  signal d16_r: std_logic_vector(15 downto 0);
  signal d_out : std_logic_vector(1 downto 0);
  signal shift : std_logic_vector(15 downto 0);
  signal busy : std_logic := '0';
  signal cycle : std_logic;
  signal shift_count : unsigned(1 downto 0);
  signal frame : std_logic_vector(3 downto 0);
  signal r_frame : std_logic_vector(3 downto 0);
  signal bcoclk_r : std_logic;
  signal cmd : std_logic_vector(3 downto 0) := "1000";
  type state_t is ( idle, shifting, send, done );
  signal state : state_t := idle;

begin

  oddr_imp : oddr
  generic map (
    ddr_clk_edge => "SAME_EDGE"
  )
  port map (
    c => sysclk,
    q => tclkb_out,
    ce => '1',
    d1 => d_out(0),  -- sampled on rising edge of sysclk
    d2 => d_out(1)
  );

  process ( sysclk ) begin
    if ( sysclk'event and sysclk = '1' ) then
      if ( bcoclk = '0' ) then
        d_out <= r_frame(1 downto 0);
      else
        d_out <= r_frame(3 downto 2); 
      end if;
    end if;
  end process;

  process ( bcoclk ) begin
    if ( bcoclk'event and bcoclk = '1' ) then
      r_frame <= frame;
      dv_r <= dv;
      d_r <= d;
      busy_r <= busy;
      dv16_r <= dv16;
      d16_r <= d16;
      case state is
      when idle =>
        if ( dv_r = '1' ) then
          shift <= x"333" & d_r;
          state <= shifting;
          busy <= '1';
          shift_count <= "01";
        elsif ( busy_r = '0' and dv16_r = '1' ) then
          shift <= d16_r;
          state <= shifting;
          busy <= '1';
          shift_count <= "11";
        end if;
      when shifting =>
        if ( shift_count = "00" ) then
          state <= done;
        else
          shift_count <= shift_count - 1;
          shift <= "0000" & shift(15 downto 4);
        end if;
      when done =>
        if ( dv16_r = '0' ) then
          busy <= '0';
          state <= idle;
        end if;
      when others =>
        state <= idle;
      end case;
    end if;
  end process;

  frame <= cmd when state = send else
           shift(3 downto 0) when state = shifting else "0011";
  ack16 <= busy;

end Behavioral;
