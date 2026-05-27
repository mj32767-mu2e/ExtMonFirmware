--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    12:34:00 10/04/2016 
-- Design Name:    amc502
-- Module Name:    xaui_arpreq - RTL
-- Project Name:   
-- Target Devices: Kintex-7 family
-- Tool versions:  Vivado 2016.1
-- Description:    Sends ARP request packet
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

entity xaui_arpreq is
  port (
    reset : in std_logic;
    clk : in std_logic;
    strobe : in std_logic;
    src_ha : in std_logic_vector(47 downto 0);
    src_ip : in std_logic_vector(31 downto 0);
    target_ip : in std_logic_vector(31 downto 0);
    my_netmask : in std_logic_vector(31 downto 0);
    gw_ip_address : in std_logic_vector(31 downto 0);
    dout : out std_logic_vector(63 downto 0);
    cout : out std_logic_vector(7 downto 0);
    fcs : out std_logic;
    request : out std_logic;
    grant : in std_logic
  );
end xaui_arpreq;

architecture RTL of xaui_arpreq is
  type State_t is ( Idle, RequestAccess, Preamble,
                    Word0, Word1, Word2, Word3, Word4, Word5, Word6,
                    FrameCheckSum, Done );
  signal state : State_t := Idle;
  signal my_network : std_logic_vector(31 downto 0);
  signal target_network : std_logic_vector(31 downto 0);
  signal last_strobe : std_logic;
  signal src_ha_r : std_logic_vector(47 downto 0);
  signal src_ip_r : std_logic_vector(31 downto 0);
  signal target_ip_r : std_logic_vector(31 downto 0);

begin

  process ( clk, reset ) begin
    if ( clk'event and clk = '1' ) then     -- data is valid on the rising edge
      if ( reset = '1' ) then
        request <= '0';
        dout <= x"0707070707070707";
        cout <= x"ff";
        fcs <= '0';
        state <= Idle;
      else
        case state is
          when Idle =>
            if ( strobe = '1' and last_strobe = '0' ) then
              request <= '1';
              dout <= x"0707070707070707";
              cout <= x"ff";
              fcs <= '0';
              src_ha_r <= src_ha;
              src_ip_r <= src_ip;
              target_ip_r <= target_ip;
              my_network <= my_netmask and gw_ip_address;
              target_network <= my_netmask and target_ip;
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
            dout <= x"d5555555555555fb";
            cout <= x"01";
            state <= Word0;
          when Word0 =>
            dout <= src_ha_r(39 downto 32) & src_ha_r(47 downto 40) &
                    x"ffffffffffff";
            cout <= x"00";
            state <= Word1;
          when Word1 =>
            dout <= x"01000608" &
                    src_ha_r(7 downto 0) & src_ha_r(15 downto 8) &
                    src_ha_r(23 downto 16) & src_ha_r(31 downto 24);
            cout <= x"00";
            state <= Word2;
          when Word2 =>
            dout <= src_ha_r(39 downto 32) & src_ha_r(47 downto 40) &
                    x"010004060008";
            cout <= x"00";
            state <= Word3;
          when Word3 =>
            dout <= src_ip_r(7 downto 0) & src_ip_r(15 downto 8) &
                    src_ip_r(23 downto 16) & src_ip_r(31 downto 24) &
                    src_ha_r(7 downto 0) & src_ha_r(15 downto 8) &
                    src_ha_r(23 downto 16) & src_ha_r(31 downto 24);
            cout <= x"00";
            state <= Word4;
          when Word4 =>
            dout <= target_ip_r(23 downto 16) & target_ip_r(31 downto 24) &
                    x"000000000000";
            cout <= x"00";
            state <= Word5;
          when Word5 =>
            dout <= x"000000000000" &
                    target_ip_r(7 downto 0) & target_ip_r(15 downto 8);
            cout <= x"00";
            state <= Word6;
          when Word6 =>
            dout <= x"0000000000000000";
            cout <= x"00";
            state <= FrameCheckSum;
          when FrameCheckSum =>
            dout <= x"0000000000000000";
            cout <= x"f0";
            fcs <= '1';
            state <= Done;
          when Done =>
            dout <= x"07070707070707fd";
            cout <= x"ff";
            fcs <= '0';
            state <= Idle;
        end case;
      end if;
      last_strobe <= strobe;
    end if;
  end process;

end RTL;
