
--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    02:42:00 12/14/2018 
-- Design Name:    amc502
-- Module Name:    xaui_udp - RTL
-- Project Name:   amc502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Parses UDP packets on the XAUI interface
--
-- Dependencies:
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--  
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity xaui_udp is
  port ( reset : in  std_logic;
         clk : in  std_logic;
         enable : in  std_logic;
         din : in std_logic_vector(63 downto 0);
         cin : in std_logic_vector(7 downto 0);
         src_port : out std_logic_vector(15 downto 0);
         dst_port : out std_logic_vector(15 downto 0);
         length : out std_logic_vector(15 downto 0);
         udp_data_we : out std_logic;
         udp_buffer_clear : out std_logic
       );
end xaui_udp;

architecture RTL of xaui_udp is
  type state_t is ( idle,
                    udp_word1,
                    udp_word2,
                    udp_word3
                  );
  signal state : state_t := Idle;
  signal gated_udp_data_we : std_logic;

begin

  process ( clk, reset, enable ) begin
    if ( clk'event and clk = '1' ) then  -- Registered data is valid at rising edge
      if ( reset = '1' ) then
        src_port <= ( others => '0' );
        dst_port <= ( others => '0' );
        length <= ( others => '0' );
        gated_udp_data_we <= '0';
        udp_buffer_clear <= '1';
        state <= idle;
      elsif ( enable = '0' ) then
        gated_udp_data_we <= '0';
        udp_buffer_clear <= '0';
        state <= idle;
      else
        case state is
          when idle =>
            state <= udp_word1;
          when udp_word1=>
            src_port(15 downto 8) <= din(23 downto 16);
            src_port(7 downto 0) <= din(31 downto 24);
            dst_port(15 downto 8) <= din(39 downto 32);
            dst_port(7 downto 0) <= din(47 downto 40);
            length(15 downto 8) <= din(55 downto 48);
            length(7 downto 0) <= din(63 downto 56);
            udp_buffer_clear <= '1';    -- Assert buffer clear for one cycle
            state <= udp_word2;
          when udp_word2 =>
            udp_buffer_clear <= '0';
            gated_udp_data_we <= '1';
            state <= udp_word3;
          when others =>  
--  Remain here until enable is deasserted
        end case;
      end if;
    end if;
  end process;

  udp_data_we <= gated_udp_data_we and enable;

end RTL;
