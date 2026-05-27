--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    10:28:50 06/13/2016 
-- Design Name:    amc502
-- Module Name:    ipbuf - RTL
-- Project Name:   amc502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Implements a FIFO that computes the length and
--                 the 16-bit ones's compliment checksum as data is
--                 shifted in.
--
-- Dependencies:
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ipbuf is
  generic ( size : integer := 1024 );
  port ( reset : in std_logic;
         clk : in std_logic;
         din : in std_logic_vector(7 downto 0);
         wr_en : in std_logic;
         rd_en : in std_logic;
         dout : out std_logic_vector(7 downto 0);
         length : out std_logic_vector(15 downto 0);
         clear : in std_logic;
         cksum : out std_logic_vector(15 downto 0)
       );
end ipbuf;

architecture RTL of ipbuf is

  signal high_byte : std_logic;
  signal sum : unsigned(17 downto 0);
  signal extend_high : std_logic_vector(15 downto 0);
  signal extend_low : std_logic_vector(15 downto 0);

  signal fifo_valid : std_logic := '0';

  signal read_address : integer range 0 to size-1;
  signal write_address : integer range 0 to size-1;

  type fifo_t is array(size-1 downto 0) of std_logic_vector(7 downto 0);
  signal fifo : fifo_t;

begin

  process ( clk, wr_en, rd_en, clear, reset ) begin 
    if ( clk'event and clk = '1' ) then
      if ( reset = '1' ) then
        high_byte <= '1';
        sum <= ( others => '0' );
        read_address <= 0;
        write_address <= 0;
        fifo_valid <= '0';
      elsif ( clear = '1' ) then
        high_byte <= '1';
        sum <= ( others => '0' );
        read_address <= 0;
        write_address <= 0;
        fifo_valid <= '0';
      elsif ( wr_en = '1' ) then
        fifo_valid <= '1';
        fifo(write_address) <= din;
        write_address <= write_address + 1;

        if ( high_byte = '0' ) then
          sum <= "00" & sum(15 downto 0) + unsigned(extend_high) + sum(17 downto 16);
        else
          sum <= "00" & sum(15 downto 0) + unsigned(extend_low) + sum(17 downto 16);
        end if;
        high_byte <= not high_byte;
      else
        sum <= "00" & sum(15 downto 0) + sum(17 downto 16);
      end if;
      if ( rd_en = '1' ) then
        read_address <= read_address + 1;
      end if;
      dout <= fifo(read_address);
    end if;
  end process;

  extend_high <= x"00" & din;
  extend_low <= din & x"00";
  cksum <= std_logic_vector(sum(15 downto 0));
  length <= std_logic_vector(to_unsigned(write_address,16));
  
end RTL;
