--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    10:56:38 06/14/2016 
-- Design Name:    amc502
-- Module Name:    i2c - RTL
-- Project Name:   AMC502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    i2c bus interface
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

entity i2c is
  port (
    clk : in std_logic;

    scl : out std_logic;
    sda_out : out std_logic;
    sda_in : in std_logic;
    sda_t : out std_logic;

    strobe : in std_logic;
    ready : out std_logic;
    nwrite : in std_logic_vector(7 downto 0);
    nread : in std_logic_vector(7 downto 0);

    address : in std_logic_vector(7 downto 0);

    daddr : out std_logic_vector(7 downto 0);
    din : in std_logic_vector(7 downto 0);
    den : out std_logic;

    dout : out std_logic_vector(7 downto 0);
    wen : out std_logic;

    nack : out std_logic;
    nbyte : out std_logic_vector(7 downto 0)
  );
end i2c;

architecture RTL of i2c is

  signal i2c_write : std_logic_vector(23 downto 0);
  signal i2c_read : std_logic_vector(7 downto 0);

  signal i2c_divider : unsigned(7 downto 0) := "00000000";
  signal i : integer range 0 to 7;
  
  type i2c_state_t is ( Idle, Start, Write, Read, PauseRead, Restart,
                        Ack, SendAck, SendNAck, Stop, Done );
  signal i2c_state : i2c_state_t := Idle;
  signal i2c_clock : std_logic;
  signal i2c_start : std_logic;
  signal i2c_restart : std_logic;
  signal i2c_stop : std_logic;
  signal rw : std_logic;
  signal i2c_nack : std_logic := '0';
  signal i2c_daddr : std_logic_vector(7 downto 0);
  signal byte : std_logic_vector(7 downto 0);
  signal ulen : unsigned(7 downto 0);
  signal nw : unsigned(7 downto 0);
  signal nr : unsigned(7 downto 0);
  signal sda_in_r : std_logic;
  signal divider_stuff : std_logic_vector(1 downto 0);

  attribute mark_debug : string;
  attribute dont_touch : string;
  attribute mark_debug of i2c_state : signal is "true";
  attribute dont_touch of i2c_state : signal is "true";
  attribute mark_debug of byte : signal is "true";
  attribute dont_touch of byte : signal is "true";
  attribute mark_debug of i2c_daddr : signal is "true";
  attribute dont_touch of i2c_daddr : signal is "true";
--  attribute mark_debug of i2c_divider : signal is "true";
--  attribute mark_debug of i2c_clock : signal is "true";
--  attribute mark_debug of i2c_start : signal is "true";
--  attribute mark_debug of i2c_stop : signal is "true";
--  attribute mark_debug of i2c_nack : signal is "true";
--  attribute mark_debug of i : signal is "true";

begin

  process ( clk ) begin
    if ( clk'event and clk = '1' ) then
      sda_in_r <= sda_in;
      i2c_divider <= i2c_divider + 1;
      divider_stuff <= std_logic_vector(i2c_divider(7 downto 6));
      if ( i2c_divider = "00000000" ) then
        case i2c_state is
          when Idle =>
            if ( strobe = '1' ) then
              nw <= ( others => '0' );
              nr <= ( others => '0' );
              i2c_state <= Start;
              i2c_daddr <= ( others => '0' );
              if ( nwrite /= "00000000" ) then
                ulen <= unsigned(nwrite);
                rw <= '0';
              else
                ulen <= unsigned(nread);
                rw <= '1';
              end if;
            end if;
          when Start =>
            i2c_nack <= '0';
            byte <= address(7 downto 1) & rw;
            i <= 7;
            i2c_state <= Write;
          when Restart =>
            i2c_nack <= '0';
            i2c_daddr <= ( others => '0' );
            byte <= address(7 downto 1) & rw;
            ulen <= unsigned(nread)-1;
            i <= 7;
            i2c_state <= Write;
          when Write =>
            if ( i = 0 ) then
              i2c_state <= Ack;
            else
              i <= i - 1;
              i2c_state <= Write;
            end if;
          when Read =>
            if ( i = 0 ) then
              if ( nr = ulen ) then
                i2c_state <= SendNAck;
              else
                i2c_state <= SendAck;
              end if;
            else
              i <= i - 1;
              i2c_state <= Read;
            end if;
          when Ack =>
            i <= 7;
            nw <= nw + 1;
            if ( rw = '0' and nw = ulen ) then
              if ( nread /= "00000000" ) then
                i2c_state <= Restart;
                rw <= '1';
              else
                i2c_state <= Stop;
              end if;
            elsif ( rw = '0' ) then  -- Write
              byte <= din;
              i2c_daddr <= std_logic_vector(unsigned(i2c_daddr)+1);
              i2c_state <= Write;
            else
              i2c_state <= PauseRead;
            end if;
          when PauseRead =>
            i2c_state <= Read;
          when SendAck =>
            nr <= nr + 1;
            i <= 7;
            i2c_daddr <= std_logic_vector(unsigned(i2c_daddr)+1);
            i2c_state <= Read;
          when SendNAck =>
            nr <= nr + 1;
            i2c_state <= Stop;
          when Stop =>
            i2c_state <= Done;
          when Done =>
            if ( strobe = '0' ) then
              i2c_state <= Idle;
            else
              i2c_state <= Done;
            end if;
        end case;
      elsif ( i2c_divider = "10000000" ) then
        if ( i2c_state = Read ) then
          byte(i) <= sda_in_r;
        elsif ( i2c_state = Ack ) then
          i2c_nack <= sda_in_r;
          if ( i2c_nack = '1' ) then
            i2c_state <= Stop;
          end if;
        end if;
      end if;
    end if;
  end process;

  i2c_clock <= divider_stuff(0) xor divider_stuff(1);
  i2c_start <= '1' when divider_stuff = "00" else '0';
  i2c_restart <= not divider_stuff(1);
  i2c_stop <= '1' when divider_stuff = "11" else '0';
  ready <= '1' when i2c_state = Idle else '0';

  scl <= '1' when i2c_state = Idle else
         '1' when i2c_state = Done else
         '1' when i2c_state = Start and divider_stuff(1) = '0' else
         '1' when i2c_state = Stop and divider_stuff(1) = '1' else
         '0' when i2c_state = PauseRead else
         i2c_clock;

  sda_out <= '1' when i2c_state = Idle else
             '1' when i2c_state = Done else
             '1' when i2c_state = Ack else
             '1' when i2c_state = PauseRead else
             '0' when i2c_state = SendAck else
             '1' when i2c_state = SendNAck else
             '1' when i2c_state = Read else
             i2c_start when i2c_state = Start else
             i2c_restart when i2c_state = Restart else
             i2c_stop when i2c_state = Stop else
             byte(i) when i2c_state = Write else
             '0';

  sda_t <= '1' when i2c_state = Ack else
           '1' when i2c_state = Read else
           '1' when i2c_state = PauseRead else
           '0';

  den <= '1' when ( i2c_state = Start or i2c_state = Ack ) and i2c_divider = "10000000" else '0';
  wen <= '1' when i2c_state = SendNAck and i2c_divider = "00000000" else
         '1' when i2c_state = SendAck and i2c_divider = "00000000" else '0';
  dout <= byte;

  nbyte <= std_logic_vector(nw);
  nack <= i2c_nack;
  daddr <= i2c_daddr;

end RTL;
