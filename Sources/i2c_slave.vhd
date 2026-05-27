--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    04:04:38 01/08/2019 
-- Design Name:    amc502
-- Module Name:    i2c_slave - behavioral
-- Project Name:   AMC502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    i2c bus slave interface
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

entity i2c_slave is
  port (
    clk : in std_logic;
    scl : in std_logic;
    sda_in : in std_logic;
    sda_out : out std_logic;
    sda_t : out std_logic;
    address : out std_logic_vector(31 downto 0);
    write_data : out std_logic_vector(31 downto 0);
    read_data : in std_logic_vector(31 downto 0);
    address_strobe : out std_logic;
    read_strobe : out std_logic;
    write_strobe : out std_logic
  );
end i2c_slave;

architecture behavioral of i2c_slave is

  signal sda_r : std_logic_vector(6 downto 0);
  signal scl_r : std_logic_vector(6 downto 0);
  signal sda_steady : std_logic;
  signal scl_steady : std_logic;
  signal sda_stop : std_logic;
  signal sda_start : std_logic;
  signal scl_rising : std_logic;
  signal ack_out : std_logic;
  signal sda_t_out : std_logic;
  signal scl_falling : std_logic;
  signal shift : std_logic_vector(31 downto 0);
  signal read_word : std_logic_vector(31 downto 0);
  type edge_t is ( Steady, Transition, Waiting );
  signal sda_edge : edge_t := Steady;
  signal scl_edge : edge_t := Steady;
  type state_t is ( Idle, Start, Stop, AlmostAck, Ack, AlmostReadAck,
                    ReadAck, Nack, Read, Write, WriteWord, ReadWord, LatchWord );
  signal state : state_t := Idle;
  signal next_state : state_t;
  signal count : unsigned(2 downto 0);
  signal addr : std_logic_vector(7 downto 0);
  type reg_t is array(15 downto 0) of std_logic_vector(7 downto 0);
  signal regs : reg_t;
  signal write_address : std_logic;

  constant i2c_addr : std_logic_vector(7 downto 0) := x"3c";

--  attribute mark_debug : string;
--  attribute mark_debug of state : signal is "true";
--  attribute mark_debug of addr : signal is "true";
--  attribute mark_debug of count : signal is "true";
--  attribute mark_debug of sda_in : signal is "true";
--  attribute mark_debug of sda_out : signal is "true";
--  attribute mark_debug of sda_t : signal is "true";
--  attribute mark_debug of scl : signal is "true";

begin

  process ( clk ) begin
    if ( clk'event and clk = '1' ) then
      sda_r <= sda_r(sda_r'left-1 downto 0) & sda_in;
      scl_r <= scl_r(scl_r'left-1 downto 0) & scl;

      case sda_edge is
      when Steady =>
        sda_stop <= '0'; 
        sda_start <= '0'; 
        if ( sda_steady = '0' ) then
          sda_edge <= Transition;
        end if;
      when Transition =>
        if ( scl = '1' ) then
          if ( sda_t_out = '1' and sda_in = '0' ) then
            sda_start <= '1';
            sda_stop <= '0';
          elsif ( sda_t_out = '1' and sda_in = '1' ) then
            sda_start <= '0';
            sda_stop <= '1';
          end if;
        end if;
        sda_edge <= Waiting;
      when Waiting =>
        sda_stop <= '0'; 
        sda_start <= '0';
        if ( sda_steady = '1' ) then
          sda_edge <= Steady;
        end if;
      end case;

      case scl_edge is
      when Steady =>
        if ( scl_steady = '0' ) then
          scl_edge <= Transition;
        end if;
      when Transition =>
        if ( scl = '0' ) then
          scl_falling <= '1';
          scl_rising <= '0';
        else
          scl_falling <= '0';
          scl_rising <= '1';
        end if;
        scl_edge <= Waiting;
      when Waiting =>
        scl_rising <= '0'; 
        scl_falling <= '0';
        if ( scl_steady = '1' ) then
          scl_edge <= Steady;
        end if;
      end case;

      case state is
      when Idle =>
        sda_t_out <= '1';
        ack_out <= '1';
        if ( sda_start = '1' ) then
          state <= Start;
          count <= ( others => '0' );
        end if;
      when Start =>
        sda_t_out <= '1';
        if ( scl_rising = '1' ) then
          shift <= shift(shift'left-1 downto 0) & sda_in;
          count <= count + 1;
          if ( count = "111" and shift(6 downto 0) = i2c_addr(6 downto 0) ) then
            if ( sda_in = '1' ) then
              next_state <= Read;
              count <= ( others => '0' );
            else
              next_state <= Write;
              write_address <= '1';
            end if;
            state <= AlmostAck;
          end if;
        end if;
        if ( sda_stop = '1' ) then
          state <= Stop;
        end if;
      when Stop =>
        sda_t_out <= '1';
        ack_out <= '1';
        state <= Idle;
      when AlmostAck =>
        sda_t_out <= '1';
        ack_out <= '0';
        if ( scl_falling = '1' ) then
          state <= Ack;
        end if;
      when Ack =>
        sda_t_out <= '0';
        ack_out <= '0';
        if ( scl_falling = '1' ) then
          count <= ( others => '0' );
          state <= next_state;
        end if;
      when AlmostReadAck =>
        sda_t_out <= '1';
        ack_out <= '1';
        if ( scl_rising = '1' ) then
          if ( sda_in = '0' ) then
            state <= ReadAck;
          else
            state <= Nack;
          end if;
        end if;
      when ReadAck =>
        if ( scl_falling = '1' ) then
          sda_t_out <= '0';
          ack_out <= '0';
          state <= next_state;
        end if;
      when Nack =>
        sda_t_out <= '1';
        state <= Idle;
      when Read =>
        sda_t_out <= '0';
        if ( sda_stop = '1' ) then
          state <= Stop;
        end if;
        if ( scl_falling = '1' ) then
          count <= count + 1;
          if ( count = "111" ) then
            addr <= std_logic_vector(unsigned(addr)+1);
            next_state <= Read;
            sda_t_out <= '1';
            ack_out <= '1';
            state <= AlmostReadAck;
          end if;
        end if;
      when Write =>
        sda_t_out <= '1';
        if ( sda_stop = '1' ) then
          state <= Idle;
        end if;
        if ( scl_rising = '1' ) then
          shift <= shift(shift'left-1 downto 0) & sda_in;
          count <= count + 1;
          if ( count = "111" ) then
            if ( write_address = '1' ) then
              addr <= shift(6 downto 0) & sda_in;
              write_address <= '0';
              next_state <= Write;
            else
              regs(to_integer(unsigned(addr))) <= shift(6 downto 0) & sda_in;
              addr <= std_logic_vector(unsigned(addr)+1);
              if ( addr = "00001100" ) then
                if ( sda_in = '0' ) then
                  next_state <= WriteWord;
                else
                  next_state <= ReadWord;
                end if;
              else
                next_state <= Write;
              end if;
            end if;
            state <= AlmostAck;
          end if;
        end if;
      when WriteWord =>
        state <= Write;
      when ReadWord =>
        state <= LatchWord;
      when LatchWord =>
        read_word <= read_data;
        state <= Write;
      end case; 
    end if;
  end process;
  address <= regs(3) & regs(2) & regs(1) & regs(0);
  write_data <= regs(7) & regs(6) & regs(5) & regs(4);
  sda_steady <= '1' when sda_r(sda_r'left downto sda_r'left-2) = sda_r(2 downto 0) else '0';
  scl_steady <= '1' when scl_r(scl_r'left downto scl_r'left-2) = scl_r(2 downto 0) else '0';
  sda_out <= read_word(31-to_integer(unsigned(count))) when state = Read and addr = x"0b" else
             read_word(23-to_integer(unsigned(count))) when state = Read and addr = x"0a" else
             read_word(15-to_integer(unsigned(count))) when state = Read and addr = x"09" else
             read_word(7-to_integer(unsigned(count))) when state = Read and addr = x"08" else
             regs(to_integer(unsigned(addr)))(7-to_integer(unsigned(count))) when state = Read else ack_out;
  sda_t <= sda_t_out;

  address_strobe <= '1' when state = WriteWord else
                    '1' when state = ReadWord else '0';
  write_strobe <= '1' when state = WriteWord else '0';
  read_strobe <= '1' when state = ReadWord else '0';

end behavioral;
