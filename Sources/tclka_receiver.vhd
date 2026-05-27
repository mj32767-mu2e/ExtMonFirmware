--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    15:48:38 11/25/2018 
-- Design Name:    amc502
-- Module Name:    tclka_receiver - Behavioral
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
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity tclka_receiver is
  generic (
    iobdelay_value : integer := 0
  );
  port (
    sysclk : in std_logic;
    bcoclk : in std_logic;
    tclka_in : in std_logic;
    do_idelay : in std_logic;
    idelay_busy : out std_logic;
    idelay_rst : in std_logic;
    idelay_inc : in std_logic;
    idelay_tap : out std_logic_vector(5 downto 0);
    strobe : out std_logic_vector(15 downto 0)
  );
end tclka_receiver;

architecture Behavioral of tclka_receiver is

  signal bits : std_logic_vector(1 downto 0);
  signal morebits : std_logic_vector(1 downto 0);
--  signal cycle : std_logic;
  signal r_strobe : std_logic_vector(15 downto 0);
  signal cmd : std_logic_vector(3 downto 0);
  signal tap : unsigned(5 downto 0) := to_unsigned(iobdelay_value,6);
  signal tap_busy : std_logic := '0';
  signal idelay_clken : std_logic := '0';
  signal cntvalueout : std_logic_vector(4 downto 0);
  signal cinvctrl : std_logic := '0';
  signal tclka : std_logic;
  signal latch_buffer : std_logic_vector(15 downto 0);

begin

  idly_imp : idelaye2
  generic map (
    idelay_type => "VAR_LOAD",
    delay_src => "IDATAIN"
  )
  port map (
    c => sysclk,
    regrst => idelay_rst,
    ld => '0',
    ce => idelay_clken,
    inc => idelay_inc,
    cinvctrl => cinvctrl,
    cntvaluein => "00000",
    idatain => tclka_in,
    datain => '0',
    dataout => tclka,
    ldpipeen => '0',
    cntvalueout => cntvalueout
  );

  iddr_imp : iddr
  generic map (
    ddr_clk_edge => "SAME_EDGE_PIPELINED"
  )
  port map (
    c => sysclk,
    d => tclka,
    ce => '1',
    q1 => bits(0),
    q2 => bits(1)     --- stable on rising edge of sysclk
  );
 
  process ( sysclk, do_idelay ) begin
    if ( sysclk'event and sysclk = '1' ) then
      if ( idelay_clken = '1' ) then
        if ( idelay_rst = '1' ) then
          tap <= "000000";
        elsif ( idelay_inc = '1' ) then
          tap <= tap + 1;
        else
          tap <= tap - 1;
        end if;
      end if;
    end if;
  end process;

  process ( sysclk, do_idelay ) begin
    if ( sysclk'event and sysclk = '1' ) then
      if ( idelay_clken = '1' ) then
        idelay_clken <= '0';
      end if;
      if ( do_idelay = '1' and tap_busy = '0' ) then
        idelay_clken <= '1';
        tap_busy <= '1';
      elsif ( do_idelay = '0' and tap_busy = '1' ) then
        tap_busy <= '0';
      end if;
    end if;
  end process;
  idelay_tap <= cinvctrl & cntvalueout;
  idelay_busy <= tap_busy;

  process ( sysclk ) begin
    if ( sysclk'event and sysclk = '1' ) then
      if ( idelay_clken = '1' ) then
        if ( idelay_inc = '1' ) then
          if ( cntvalueout = "11111" ) then
            cinvctrl <= not cinvctrl;
          end if;
        else
          if ( cntvalueout = "00000" ) then
            cinvctrl <= not cinvctrl;
          end if;
        end if;
      end if;
    end if;
  end process;
 
  process ( sysclk ) begin
    if ( sysclk'event and sysclk = '0' ) then
--      cycle <= bcoclk;   -- Safe to sample bcoclk on falling edge of sysclk
--      if ( cycle = '0' ) then  -- bcoclk = 0
      if ( bcoclk = '1' ) then
        morebits <= bits;
      else                     -- bcoclk = 1
        latch_buffer <= latch_buffer(11 downto 0) & morebits & bits;
        case latch_buffer(11 downto 8) is
        when "0000" =>
          r_strobe <= "0000000000000001";
        when "0001" =>
          r_strobe <= "0000000000000010";
        when "0010" =>
          r_strobe <= "0000000000000100";
        when "0011" =>
          r_strobe <= "0000000000001000";
        when "0100" =>
          r_strobe <= "0000000000010000";
        when "0101" =>
          r_strobe <= "0000000000100000";
        when "0110" =>
          r_strobe <= "0000000001000000";
        when "0111" =>
          r_strobe <= "0000000010000000";
        when "1000" =>
          r_strobe <= "0000000100000000";
        when "1001" =>
          r_strobe <= "0000001000000000";
        when "1010" =>
          r_strobe <= "0000010000000000";
        when "1011" =>
          r_strobe <= "0000100000000000";
        when "1100" =>
          r_strobe <= "0001000000000000";
        when "1101" =>
          r_strobe <= "0010000000000000";
        when "1110" =>
          r_strobe <= "0100000000000000";
        when "1111" =>
          r_strobe <= "1000000000000000";
        end case;

      end if;
    end if;
  end process;

  process ( bcoclk ) begin
    if ( bcoclk'event and bcoclk = '1' ) then
      strobe <= r_strobe;
    end if;
  end process;

end Behavioral;
