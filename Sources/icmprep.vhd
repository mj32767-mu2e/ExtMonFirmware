
--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    10:21:18 06/13/2016 
-- Design Name:    amc502
-- Module Name:    icmprep - RTL
-- Project Name:   amc502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Sends ICMP reply packets
--
-- Dependencies:   add8
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity icmprep is
  generic ( id : integer := 0 );
  port ( reset : in std_logic;
         clk : in std_logic;
         strobe : in std_logic;
         din : in std_logic_vector(7 downto 0);
         wr_en : in std_logic;
         clear : in std_logic;
         protocol : out std_logic_vector(7 downto 0);
         length : out std_logic_vector(15 downto 0);
         ip_header_cksum : in std_logic_vector(15 downto 0);
         dout : out std_logic_vector(7 downto 0);
         request : out std_logic;
         enable : in std_logic_vector(3 downto 0)
       );
end icmprep;

architecture RTL of icmprep is
  type state_t is ( Idle,
                    Checksum0, Checksum1, Checksum2,
                    Header,
                    Icmp_type, Icmp_code,
                    Icmp_checksum0, Icmp_checksum1,
                    Data,
                    Done
                  );
  signal state : state_t := Idle;
  signal count : unsigned(15 downto 0);
  signal ipbuf_dout : std_logic_vector(7 downto 0);
  signal ipbuf_din : std_logic_vector(7 downto 0);
  signal ipbuf_dini : std_logic_vector(7 downto 0);
  signal ipbuf_read_enable : std_logic;
  signal ipbuf_length : std_logic_vector(15 downto 0);
  signal ipbuf_cksum : std_logic_vector(15 downto 0);
  signal icmp_cksum : std_logic_vector(15 downto 0);
  signal cksum_input : std_logic_vector(15 downto 0);
  signal cksum_enable : std_logic;
  signal carry_low : std_logic;
  signal carry_high : std_logic;
  signal cksum_clear : std_logic := '1';
  signal ipbuf_clear : std_logic;

  component ipbuf
    port (
      reset : in std_logic;
      clk : in std_logic;
      din : in std_logic_vector(7 downto 0);
      wr_en : in std_logic;
      rd_en : in std_logic;
      dout : out std_logic_vector(7 downto 0);
      length : out std_logic_vector(15 downto 0);
      clear : in std_logic;
      cksum : out std_logic_vector(15 downto 0)
    );
  end component;

  component add8
    port (
      a : in std_logic_vector(7 downto 0);
      b : in std_logic_vector(7 downto 0);
      clk : in std_logic;
      c_in : in std_logic;
      ce : in std_logic;
      sclr : in std_logic;
      c_out : out std_logic;
      s : out std_logic_vector(7 downto 0)
    );
  end component;

begin

  ipbuf_imp : ipbuf
    port map (
      reset => reset,
      clk => clk,
      din => din,
      wr_en => wr_en,
      rd_en => ipbuf_read_enable,
      dout => ipbuf_dout,
      length => ipbuf_length,
      clear => ipbuf_clear,
      cksum => ipbuf_cksum
    );

  sum_low : add8
  port map (
    a => cksum_input(7 downto 0),
    b => icmp_cksum(7 downto 0),
    s => icmp_cksum(7 downto 0),
    clk => clk,
    ce => cksum_enable,
    sclr => cksum_clear,
    c_out => carry_low,
    c_in => carry_high
  );

  sum_high : add8
  port map (
    a => cksum_input(15 downto 8),
    b => icmp_cksum(15 downto 8),
    s => icmp_cksum(15 downto 8),
    clk => clk,
    ce => cksum_enable,
    sclr => cksum_clear,
    c_out => carry_high,
    c_in => carry_low
  );

  ipbuf_clear <= clear;

  process ( clk, reset ) begin
    if ( clk'event and clk = '1' ) then
      if ( reset = '1' ) then
        dout <= x"66";
        ipbuf_read_enable <= '0'; 
        request <= '0';
        cksum_clear <= '1';
        cksum_enable <= '0';
        state <= Idle;
      else
        case state is
          when Idle =>
            if ( strobe = '1' ) then
              request <= '1';
              count <= "000" & unsigned(ipbuf_length(12 downto 0)) - 2;
              cksum_clear <= '1';
              cksum_enable <= '0';
              ipbuf_read_enable <= '0'; 
              state <= Checksum0;
            else
              request <= '0';
              cksum_clear <= '1';
              cksum_enable <= '0';
              ipbuf_read_enable <= '0'; 
              state <= Idle;
            end if;
          when Checksum0 =>
            cksum_clear <= '0';
            cksum_enable <= '1';
            cksum_input <= ipbuf_cksum;
            state <= Checksum1;
          when Checksum1 =>
            cksum_clear <= '0';
            cksum_enable <= '1';
            cksum_input <= x"0000";
            state <= Checksum2;
          when Checksum2 =>
            cksum_clear <= '0';
            cksum_enable <= '0';
            cksum_input <= x"0000";
            state <= Header;
          when Header =>     -- We wait here until the header has been sent and the request acknowledged
            dout <= x"00";              -- icmp response
            if ( to_integer(unsigned(enable)) = id ) then
              dout <= x"00";
              state <= Icmp_code;
            end if;
          when Icmp_code =>
            dout <= not icmp_cksum(15 downto 8);
            state <= Icmp_checksum0;
            ipbuf_read_enable <= '1';
          when Icmp_checksum0 =>
            dout <= not icmp_cksum(7 downto 0);
            if ( count = 0 ) then
              state <= Done;
            else
              state <= Icmp_checksum1;
            end if;
          when Icmp_checksum1 =>
            dout <= ipbuf_dout;
            state <= Data;
          when Data =>
            dout <= ipbuf_dout;
            if ( count = 0 ) then
              state <= Done;
            else
              count <= count - 1;
            end if;
          when others =>
            request <= '0';
            if ( strobe = '0' ) then
              state <= Idle;
              ipbuf_read_enable <= '0'; 
              cksum_clear <= '0';
            end if;
        end case;
      end if;
    end if;
  end process;

--  this counts the payload, the 20 byte ip header + 4 bytes for the icmp type/code and checksum

  length <= "000" & std_logic_vector(unsigned(ipbuf_length(12 downto 0))+24);
  protocol <= x"01";

end RTL;
