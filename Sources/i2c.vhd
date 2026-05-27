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
    len : in std_logic_vector(7 downto 0);

    address : in std_logic_vector(6 downto 0);
    rw : in std_logic;

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
  
  type i2c_state_t is ( Idle, Start, Pause, Write, Read,
                        Ack, SendAck, SendNAck, Stop, Done );
  signal i2c_state : i2c_state_t := Idle;
  signal i2c_clock : std_logic;
  signal i2c_start : std_logic;
  signal i2c_stop : std_logic;
  signal i2c_nack : std_logic := '0';
  signal byte : std_logic_vector(7 downto 0);
  signal ulen : unsigned(7 downto 0);
  signal nwrite : unsigned(7 downto 0);
  signal sda_in_r : std_logic;
  signal divider_stuff : std_logic_vector(1 downto 0);

--  attribute mark_debug : string;
--  attribute mark_debug of i2c_state : signal is "true";
--  attribute mark_debug of i2c_divider : signal is "true";
--  attribute mark_debug of i2c_clock : signal is "true";
--  attribute mark_debug of i2c_start : signal is "true";
--  attribute mark_debug of i2c_stop : signal is "true";
--  attribute mark_debug of i2c_nack : signal is "true";
--  attribute mark_debug of byte : signal is "true";
--  attribute mark_debug of i : signal is "true";

begin

  process ( clk ) begin
    if ( clk'event and clk = '1' ) then
      sda_in_r <= sda_in;
      if ( i2c_divider = "11111111" ) then
        case i2c_state is
          when Idle =>
            if ( strobe = '1' ) then
              ready <= '0';
              ulen <= unsigned(len);
              nwrite <= ( others => '0' );
              i2c_state <= Start;
            else
              ready <= '1';
              i2c_state <= Idle;
            end if;
          when Start =>
            i2c_nack <= '0';
            i2c_state <= Pause;
          when Pause =>
            i2c_state <= Write;
            byte <= address & rw;
            i <= 7;
          when Write =>
            if ( i = 0 ) then
              if ( nwrite = x"00" ) then
                i2c_state <= Ack;  -- Read ACK after address
              elsif ( rw = '1' ) then
                if ( nwrite = ulen - 1 ) then
                  i2c_state <= SendNAck;  -- Send NACK on last byte
                else
                  i2c_state <= SendAck;  -- Send ACK after each byte
                end if;
              else
                i2c_state <= Ack;  -- Read ACK after each byte
              end if;
            else
              i <= i - 1;
              i2c_state <= Write;
            end if;
          when Read =>
            if ( i = 0 ) then
              if ( nwrite = ulen-1 ) then
                i2c_state <= SendNAck;
              else
                i2c_state <= SendAck;
              end if;
            else
              i <= i - 1;
              i2c_state <= Read;
            end if;
          when Ack =>
            if ( nwrite = ulen ) then
              i2c_state <= Stop;
            elsif ( rw = '0' ) then
              byte <= din;
              i <= 7;
              nwrite <= nwrite + 1;
              i2c_state <= Write;
            else
              i <= 7;
              i2c_state <= Read;
            end if;
          when SendAck =>
            i <= 7;
            nwrite <= nwrite + 1;
            i2c_state <= Read;
          when SendNAck =>
            nwrite <= nwrite + 1;
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
      elsif ( i2c_divider = "01111111" ) then
        if ( i2c_state = Read ) then
          byte(i) <= sda_in_r;
        elsif ( i2c_state = Ack ) then
          i2c_nack <= sda_in_r;
          if ( i2c_nack = '1' ) then
            i2c_state <= Stop;
          end if;
        end if;
      end if;
      i2c_divider <= i2c_divider + 1;
      divider_stuff <= std_logic_vector(i2c_divider(7 downto 6));
    end if;
  end process;

  i2c_clock <= divider_stuff(0) xor divider_stuff(1);
  i2c_start <= '1' when divider_stuff = "00" else '0';
  i2c_stop <= '1' when divider_stuff = "11" else '0';

  scl <= '1' when i2c_state = Idle else
         '1' when i2c_state = Done else
         '0' when i2c_state = Pause else
         '1' when i2c_state = Start and divider_stuff(1) = '0' else
         '1' when i2c_state = Stop and divider_stuff(1) = '1' else
         i2c_clock;

  sda_out <= '1' when i2c_state = Idle else
             '1' when i2c_state = Done else
             '1' when i2c_state = Ack else
             '0' when i2c_state = SendAck else
             '1' when i2c_state = SendNAck else
             '1' when i2c_state = Read else
             '0' when i2c_state = Pause else
             i2c_start when i2c_state = Start else
             i2c_stop when i2c_state = Stop else
             byte(i) when i2c_state = Write else
             '0';

  sda_t <= '1' when i2c_state = Ack else
           '1' when i2c_state = Read else
           '0';

  den <= '1' when i2c_state = Ack and rw = '0' and i2c_divider = "00000000" else '0';
  wen <= '1' when i2c_state = SendNAck and i2c_divider = "00000000" else
         '1' when i2c_state = SendAck and i2c_divider = "00000000" else '0';
  dout <= byte;

  nbyte <= std_logic_vector(nwrite);
  nack <= i2c_nack;

end RTL;
