
--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    12:47:06 06/13/2016 
-- Design Name:    amc502
-- Module Name:    udp - RTL
-- Project Name:   amc502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Parses UDP packets
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

entity udp is
  port ( reset : in  std_logic;
         clk : in  std_logic;
         enable : in  std_logic;
         din : in  std_logic_vector (7 downto 0);
         src_port : out std_logic_vector(15 downto 0);
         dst_port : out std_logic_vector(15 downto 0);
         length : out std_logic_vector(15 downto 0);
         udp_data_we : out std_logic;
         udp_buffer_clear : out std_logic
       );
end udp;

architecture RTL of udp is
  type state_t is ( Idle,
                    UDP_sport0,
                    UDP_sport1,
                    UDP_dport0,
                    UDP_dport1,
                    UDP_length0,
                    UDP_length1,
                    UDP_cksum0,
                    UDP_cksum1
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
            src_port(15 downto 8) <= din;
            state <= udp_sport0;
          when udp_sport0 =>
            src_port(7 downto 0) <= din;
            state <= udp_sport1;
          when udp_sport1 =>
            dst_port(15 downto 8) <= din;
            state <= udp_dport0;
          when udp_dport0 =>
            dst_port(7 downto 0) <= din;
            udp_buffer_clear <= '1';    -- Assert buffer clear for one cycle
            state <= udp_dport1;
          when udp_dport1 =>
            length(15 downto 8) <= din;
            udp_buffer_clear <= '0';
            state <= udp_length0;
          when udp_length0 =>
            length(7 downto 0) <= din;
            state <= udp_length1;
          when udp_length1 =>
            state <= udp_cksum0;
          when udp_cksum0 =>
            state <= udp_cksum1;
            gated_udp_data_we <= '1';
          when others =>  
--  Remain here until enable is deasserted
        end case;
      end if;
    end if;
  end process;

  udp_data_we <= gated_udp_data_we and enable;

end RTL;
