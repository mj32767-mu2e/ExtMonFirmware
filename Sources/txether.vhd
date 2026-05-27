--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    08:44:16 06/06/2013 
-- Design Name:    stib
-- Module Name:    txether - RTL
-- Project Name:   STIB firmware
-- Target Devices: xc4vlx25ff668-10
-- Tool versions:  ISE 14.4 / 14.6
-- Description:    Sends Ethernet frames
--
-- Dependencies:
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity txether is
  port (
    reset : in std_logic;
    clk : in std_logic;
    saddr : in std_logic_vector(47 downto 0);
    daddr : in std_logic_vector(47 downto 0);
    sel : in std_logic_vector(15 downto 0);
    enable : out std_logic_vector(3 downto 0);
    ip_header : out std_logic;
    header : out std_logic;
    crc : out std_logic;
    ifg : out std_logic;
    din : in std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0);
    crc_out : out std_logic_vector(7 downto 0);
    txen : out std_logic
  );
end txether;

architecture RTL of txether is
  type state_t is ( Idle,
                    Preamble0, Preamble1, Preamble2,
                    Preamble3, Preamble4, Preamble5, Preamble6,
                    Start_of_frame,
                    Frame0, Frame1, Frame2, Frame3, Frame4, Frame5, Frame6,
                    Frame7, Frame8, Frame9, Frame10,
                    Payload,
                    Checksum0, Checksum1, Checksum2, InterFrameGap, Done
                  );
  signal state : state_t := Idle;
  signal load_crc : std_logic;
  signal calc_crc : std_logic;
  signal stuff : std_logic;
  signal crc_byte : std_logic_vector(7 downto 0);
  signal crc_value : std_logic_vector(31 downto 0);
  signal crc_valid : std_logic;
  signal latched_enable : std_logic_vector(3 downto 0) := "0000";
  signal sampled_enable : std_logic_vector(3 downto 0) := "0000";
  signal xout : std_logic_vector(7 downto 0);
  signal selected : std_logic;
  signal send_header : std_logic;
  signal ip_header_count : unsigned(4 downto 0);
  signal do_crc : std_logic;
  constant ifg_size : natural := 8;
  signal ifg_count : natural range 0 to ifg_size-1;

  component crc32 is
    port ( clock : in  std_logic;
           clear : in  std_logic;
           data : in  std_logic_vector (7 downto 0);
           calc : in std_logic;
           crc_byte : out std_logic_vector(7 downto 0);
           crc_reg : out std_logic_vector(31 downto 0);
           valid : out std_logic
         );
  end component;

begin

  crc32_imp : crc32
  port map (
    clock => clk,    -- all data should be stable on the rising edge of clk
    clear => load_crc,
    data => din,
    calc => calc_crc,
    crc_byte => crc_out,
    crc_reg => crc_value,
    valid => crc_valid
  );

  process ( clk, reset ) begin
    if ( clk'event and clk = '1' ) then
      if ( reset = '1' ) then
        txen <= '0';
        header <= '0';  -- changed from '1' (see comment line 7721 in notes.d)
        do_crc <= '0';
        enable <= "0000";
        ip_header <= '0';
        state <= Idle;
      else
        case state is
          when Idle =>
            enable <= "0000";
            ip_header_count <= "10110";   -- 22
            ip_header <= '0';
            if ( sel /= "0000000000000000" ) then
              header <= '1';
              dout <= x"55";
              load_crc <= '1';
              do_crc <= '0';
              txen <= '1';
              latched_enable <= sampled_enable;
              state <= Preamble0;
            end if;
          when preamble0 =>
            state <= Preamble1;
          when Preamble1 =>
            state <= Preamble2;
          when Preamble2 =>
            state <= Preamble3;
          when Preamble3 =>
            state <= Preamble4;
          when Preamble4 =>
            state <= Preamble5;
          when Preamble5 =>
            state <= Preamble6;
          when Preamble6 =>
            dout <= x"d5";
            state <= Start_of_frame;
          when Start_of_frame =>
            dout <= daddr(47 downto 40);
            load_crc <= '0';
            do_crc <= '1';
            state <= Frame0;
          when Frame0 =>
            dout <= daddr(39 downto 32);
            state <= Frame1;
          when Frame1 =>
            dout <= daddr(31 downto 24);
            state <= Frame2;
          when Frame2 =>
            dout <= daddr(23 downto 16);
            state <= Frame3;
          when Frame3 =>
            dout <= daddr(15 downto 8);
            state <= Frame4;
          when Frame4 =>
            dout <= daddr(7 downto 0);
            state <= Frame5;
          when Frame5 =>
            dout <= saddr(47 downto 40);
            state <= Frame6;
          when Frame6 =>
            dout <= saddr(39 downto 32);
            state <= Frame7;
          when Frame7 =>
            dout <= saddr(31 downto 24);
            state <= Frame8;
          when Frame8 =>
            dout <= saddr(23 downto 16);
            state <= Frame9;
          when Frame9 =>
            dout <= saddr(15 downto 8);
            state <= Frame10;
          when Frame10 =>
            dout <= saddr(7 downto 0);
            state <= Payload;
          when Payload =>
            if ( latched_enable(3 downto 2) /= "00" ) then  -- high bits indicates ip protocol
              if ( ip_header_count /= "00000" ) then
                ip_header <= '1';
                ip_header_count <= ip_header_count - 1;
              else
                ip_header <= '0';
                enable <= latched_enable;
              end if;
            else
              enable <= latched_enable;
            end if;
            if ( selected = '1' ) then
              header <= '0';           -- payload data selected by mux
              do_crc <= '0';
            else
              state <= Checksum0;
            end if;
          when Checksum0 =>
            state <= Checksum1;
          when Checksum1 =>
            state <= Checksum2;
          when Checksum2 =>
            state <= InterFrameGap;
            ifg_count <= ifg_size-1;
            txen <= '0';
          when InterFrameGap =>
            if ( ifg_count = 0 ) then
              state <= Done;
            else
              state <= InterFrameGap;
              ifg_count <= ifg_count - 1;
            end if;
          when Done =>
            state <= Idle;
        end case;
      end if;
    end if;
  end process;

  selected <= '1' when sel(to_integer(unsigned(latched_enable))) = '1' else '0';
  calc_crc <= do_crc or selected;
  crc <= '1' when ( state = Payload and selected = '0' ) or ( state = Checksum0 ) or ( state = Checksum1 ) or ( state = Checksum2 ) else '0';
  ifg <= '1' when state = InterFrameGap else '0';

  sampled_enable <= "0001" when sel(1) = '1' else
                    "0010" when sel(2) = '1' else
                    "0011" when sel(3) = '1' else
                    "0100" when sel(4) = '1' else
                    "0101" when sel(5) = '1' else
                    "0110" when sel(6) = '1' else
                    "0111" when sel(7) = '1' else
                    "1000" when sel(8) = '1' else
                    "1001" when sel(9) = '1' else
                    "1010" when sel(10) = '1' else
                    "1011" when sel(11) = '1' else
                    "0000";
end RTL;
