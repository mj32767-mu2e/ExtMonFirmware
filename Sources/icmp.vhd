--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    10:16:52 06/13/2016 
-- Design Name:    amc502
-- Module Name:    icmp - RTL
-- Project Name:   amc502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Parses ICMP packets
--
-- Dependencies:
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity icmp is
  port ( reset : in  std_logic;
         clk : in  std_logic;
         enable : in  std_logic;
         din : in  std_logic_vector (7 downto 0);
         icmp_type : out std_logic_vector(7 downto 0);
         icmp_code : out std_logic_vector(7 downto 0);
         echo_ident : out std_logic_vector(15 downto 0);
         echo_seq : out std_logic_vector(15 downto 0);
         echo_timestamp : out std_logic_vector(15 downto 0);
         icmp_data_we : out std_logic
       );
end icmp;

architecture RTL of icmp is
  type state_t is ( Idle,
                    ICMP_type_state,
                    ICMP_code_state,
                    ICMP_checksum0,
                    ICMP_checksum1,
                    ICMP_ident0,
                    ICMP_ident1,
                    ICMP_sequence0,
                    ICMP_sequence1,
                    ICMP_timestamp0,
                    ICMP_timestamp1
                  );
  signal state : state_t := Idle;
  signal gated_icmp_data_we : std_logic;
begin

  process ( clk, reset, enable ) begin
    if ( clk'event and clk = '1' ) then
      if ( reset = '1' ) then
        icmp_type <= ( others => '0' );
        icmp_code <= ( others => '0' );
        echo_ident <= ( others => '0' );
        echo_seq <= ( others => '0' );
        echo_timestamp <= ( others => '0' );
        gated_icmp_data_we <= '0';
        state <= Idle;
      elsif ( enable = '0' ) then
        gated_icmp_data_we <= '0';
        state <= Idle;
      else
        case state is
          when Idle =>
            icmp_type <= din;
            gated_icmp_data_we <= '0';
            state <= ICMP_type_state;
          when ICMP_type_state =>
            icmp_code <= din;
            state <= ICMP_code_state;
          when ICMP_code_state =>
            state <= ICMP_checksum0;
          when ICMP_checksum0 =>
            state <= ICMP_checksum1;
            gated_icmp_data_we <= '1';
          when ICMP_checksum1 =>
            echo_ident(15 downto 8) <= din;
            state <= ICMP_ident0;
          when ICMP_ident0 =>
            echo_ident(7 downto 0) <= din;
            state <= ICMP_ident1;
          when ICMP_ident1 =>
            echo_seq(15 downto 8) <= din;
            state <= ICMP_sequence0;
          when ICMP_sequence0 =>
            echo_seq(7 downto 0) <= din;
            state <= ICMP_sequence1;
          when ICMP_sequence1 =>
            echo_timestamp(15 downto 8) <= din;
            state <= ICMP_timestamp0;
          when ICMP_timestamp0 =>
            echo_timestamp(7 downto 0) <= din;
            state <= ICMP_timestamp1;
          when others =>  
--  Remain here until enable is deasserted
        end case;
      end if;
    end if;
  end process;

  icmp_data_we <= gated_icmp_data_we and enable;

end RTL;
