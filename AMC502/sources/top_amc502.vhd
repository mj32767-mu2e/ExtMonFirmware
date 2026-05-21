----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/11/2018 12:35:07 PM
-- Design Name: 
-- Module Name: top_amc502 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.00 - File Created
--
-- Additional Comments:
--
--   This top level design is for an AMC502 with no
--   interface to the FMC cards.
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity top_amc502 is
  port (
    clk100mhz1_p : in std_logic;
    clk100mhz1_n : in std_logic;
    fpga_rx_uart : in std_logic;
    fpga_tx_uart : out std_logic;
    user : in std_logic_vector(6 downto 0);
    nuled : out std_logic_vector(3 downto 0)
  );
end top_amc502;

architecture behavioral of top_amc502 is

  component microblaze_mcs_0 is
    Port ( 
      Clk : in STD_LOGIC;
      Reset : in STD_LOGIC;
      INTC_IRQ : out STD_LOGIC;
      INTC_Interrupt : in STD_LOGIC_VECTOR ( 0 to 0 );
      UART_rxd : in STD_LOGIC;
      UART_txd : out STD_LOGIC
    );

  end component microblaze_mcs_0;

  signal clk100mhz1_pre : std_logic;
  signal clk100mhz : std_logic;
  signal uart_rxd : std_logic;
  signal uart_txd : std_logic;
  signal count : unsigned(31 downto 0);
  type state_t is ( state1, state2, state3, state4, state5, state6 );
  signal state : state_t := state1;
  signal mb_reset : std_logic := '0';
  signal mb_interrupt : std_logic_vector(0 downto 0) := "0";

begin

  mb_inst : microblaze_mcs_0
  port map (
    Clk => clk100mhz,
    Reset => mb_reset,
    INTC_IRQ => open,
    INTC_Interrupt => mb_interrupt,
    UART_rxd => uart_rxd,
    UART_txd => uart_txd
  );

  clk100mhz1_ibufds_gte2_inst : ibufds_gte2
  generic map (
    clkcm_cfg => true,
    clkrcv_trst => true,
    clkswing_cfg => "11"
  )
  port map (
    o => clk100mhz1_pre,
    odiv2 => open,
    ceb => '0',
    i => clk100mhz1_p,
    ib => clk100mhz1_n
  );

  clk100mhz1_bufg_inst : bufg
  port map (
    o => clk100mhz,
    i => clk100mhz1_pre
  );

  uart_txd_obuf : obuf
  port map (
    i => uart_txd,
    o => fpga_tx_uart
  );

  uart_rxd_obuf : ibuf
  port map (
    i => fpga_rx_uart,
    o => uart_rxd
  );

  process ( clk100mhz ) begin
    if ( clk100mhz'event and clk100mhz = '1' ) then
      if ( count = x"01c9c380" ) then
        count <= ( others => '0' );
        case state is
        when state1 =>
          state <= state2;
        when state2 => 
          state <= state3;
        when state3 => 
          state <= state4;
        when state4 => 
          state <= state5;
        when state5 => 
          state <= state6;
        when state6 => 
          state <= state1;
        end case;
      else
        count <= count + 1;
      end if;
    end if;
  end process;

  nuled <= "1110" when state = state1 else
           "1101" when state = state2 else
           "1011" when state = state3 else
           "0111" when state = state4 else
           "1011" when state = state5 else
           "1101" when state = state6 else "0000";

end behavioral;
