--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    13:15:00 08/31/2021 
-- Design Name:    amc502
-- Module Name:    test_interface - RTL
-- Project Name:   AMC502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.2
-- Description:    Various internal tests
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

library unisim;
use unisim.vcomponents.all;

library hep337dev;
use hep337dev.utilities.all;
use hep337dev.iobus.all;
use hep337dev.fei4.all;
use hep337dev.test.all;

entity test_interface is
  port (
    busclk : in std_logic;
    iobus : in iobus_t;
    write_data : out std_logic_vector(31 downto 0);
    iobus_ready : out std_logic;
    bco : in std_logic_vector(47 downto 0);
    xaui_stream_clk : in std_logic;
    xaui_stream_wren : out std_logic;
    xaui_stream_strobe : out std_logic;
    xaui_stream_dout : out std_logic_vector(63 downto 0);
    xaui_stream_free : in std_logic_vector(15 downto 0);
    buffer_status : out std_logic_vector(31 downto 0);
    buffer_reset : in std_logic_vector(31 downto 0)
  );
end test_interface;

architecture RTL of test_interface is

  component fei4_trigger_fifo
    port (
      rst : in std_logic;
      clk_a : in std_logic;
      trigger : in std_logic;
      bco : in std_logic_vector(47 downto 0);
      marker : in std_logic_vector(47 downto 0);
      valid : out std_logic;
      clk_b : in std_logic;
      rden_b : in std_logic;
      dout : out std_logic_vector(127 downto 0)
    );
  end component;

  component fei4_buffer_manager_xaui
    generic (
      nbuf : integer := 4;
      buffer_size : integer := 1024
    );
    port (
      rst : in std_logic;
      clk_a : in std_logic;
      header_valid : in std_logic;
      header : in std_logic_vector(127 downto 0);
      header_read : out std_logic;
      pixel_mask : in std_logic_vector(23 downto 0);
      num_bco : in std_logic_vector(3 downto 0);
      pixel_data : in fei4_data_array_t(23 downto 0);
      pixel_dv : in std_logic_vector(23 downto 0);
      pixel_read : out std_logic_vector(23 downto 0);
      bufstat : out std_logic_vector(nbuf-1 downto 0);
      strmstat : out std_logic_vector(nbuf-1 downto 0);
      clear : in std_logic_vector(nbuf-1 downto 0);
      push : in std_logic;
      dump : in std_logic;
      rdbuf : in std_logic_vector(log2(nbuf)-1 downto 0);
      clk_b : in std_logic;
      rden_b : out std_logic;
      dout_b : out std_logic_vector(63 downto 0);
      strobe_b : out std_logic
    );
  end component;

  constant nbuf : integer := 32;

  constant base_address : std_logic_vector(15 downto 0) := x"c400";
  constant address_mask : std_logic_vector(15 downto 0) := x"ffff";
  constant address_test_csr : std_logic_vector(15 downto 0) := x"0000";
  constant address_period : std_logic_vector(15 downto 0) := x"0004";
  constant address_test_buffer_csr : std_logic_vector(15 downto 0) := x"0060";
  constant address_test_dumping_csr : std_logic_vector(15 downto 0) := x"0064";
  constant address_test_stream_csr : std_logic_vector(15 downto 0) := x"0070";
  constant address_test_mask : std_logic_vector(15 downto 0) := x"0008";

  constant zero : std_logic_vector(31 downto 0) := ( others => '0' );

  signal test_csr : std_logic_vector(31 downto 0) := x"00000001";
  signal test_buffer_csr : std_logic_vector(31 downto 0) := x"00000000";
  signal test_stream_csr : std_logic_vector(31 downto 0) := x"00000000";
  signal test_period : std_logic_vector(31 downto 0) := x"05f5e100";
  signal test_readout_mask : std_logic_vector(31 downto 0) := x"01ffffff";
  signal delay : std_logic_vector(31 downto 0) := ( others => '0' );

  signal masked_address : std_logic_vector(15 downto 0);
  signal latched_data : std_logic_vector(31 downto 0);

  signal dump_buffer : std_logic := '0';
  signal do_buffer_dump : std_logic := '0';
  signal doing_buffer_dump : std_logic;
  signal doing_buffer_dump_r : std_logic;
  signal buffer_number : std_logic_vector(log2(nbuf)-1 downto 0) := ( others => '0' );
  signal trigger_fifo_valid : std_logic;
  signal trigger_fifo_read : std_logic := '0';
  signal trigger_fifo_data : std_logic_vector(127 downto 0);
  signal test_buffer_status : std_logic_vector(nbuf-1 downto 0);
  signal test_buffer_status_r : std_logic_vector(nbuf-1 downto 0);
  signal test_stream_status : std_logic_vector(nbuf-1 downto 0);
  signal test_stream_status_r : std_logic_vector(nbuf-1 downto 0);
  signal stream_buffer_r : std_logic_vector(nbuf-1 downto 0);
  signal buffer_clear : std_logic_vector(nbuf-1 downto 0);
  signal buffer_clear_r : std_logic_vector(nbuf-1 downto 0);
  signal do_buffer_clear : std_logic := '0';
  signal do_buffer_clear_r : std_logic := '0';
  signal doing_buffer_clear : std_logic := '0';
  signal doing_buffer_clear_r : std_logic;
  signal test_fifo_read : std_logic_vector(23 downto 0) := ( others => '0' );
  signal test_data_valid : std_logic_vector(23 downto 0) := ( others => '0' );
  signal test_data : fei4_data_array_t(23 downto 0);
  signal synthetic_lv1 : std_logic;
  signal simulated_lv1 : std_logic;
  signal periodic_lv1 : std_logic;
  signal count : std_logic_vector(3 downto 0);

  attribute mark_debug : string;
--  attribute mark_debug of synthetic_lv1 : signal is "true";
--  attribute mark_debug of trigger_fifo_valid : signal is "true";
--  attribute mark_debug of trigger_fifo_read : signal is "true";
--  attribute mark_debug of buffer_clear : signal is "true";
--  attribute mark_debug of test_fifo_read : signal is "true";
--  attribute mark_debug of test_data_valid : signal is "true";
--  attribute mark_debug of test_buffer_status : signal is "true";
--  attribute mark_debug of do_buffer_dump : signal is "true";
--  attribute mark_debug of doing_buffer_dump : signal is "true";
--  attribute mark_debug of test_stream_status : signal is "true";

begin

  fei4_fifo_imp : fei4_trigger_fifo
  port map (
    rst => test_csr(31),
    clk_a => busclk,
    trigger => synthetic_lv1,
    bco => bco,
    marker => x"abaddeadbabe",
    valid => trigger_fifo_valid,
    clk_b => busclk,
    rden_b => trigger_fifo_read,
    dout => trigger_fifo_data
  );

  fei4_buf_imp : fei4_buffer_manager_xaui
  generic map (
    nbuf => nbuf
  )
  port map (
    rst => test_csr(31),
    clk_a => busclk,
    header_valid => trigger_fifo_valid,
    header => trigger_fifo_data,
    header_read => trigger_fifo_read,
    pixel_mask => test_readout_mask(23 downto 0),
    num_bco => test_readout_mask(27 downto 24),
    pixel_data => test_data,
    pixel_dv => test_data_valid,
    pixel_read => test_fifo_read,
    bufstat => test_buffer_status,
    strmstat => test_stream_status,
    clear => buffer_clear_r,
    push => test_stream_csr(30),
    dump => dump_buffer,
    rdbuf => buffer_number,
    clk_b => xaui_stream_clk,
    rden_b => xaui_stream_wren,
    dout_b => xaui_stream_dout,
    strobe_b => xaui_stream_strobe
  );

  process ( busclk )
    variable count : std_logic_vector(3 downto 0);
  begin
    if ( busclk'event and busclk = '1' ) then
      for i in 0 to 23 loop
        if ( synthetic_lv1 = '1' ) then
          if ( test_csr(3 downto 0) = "0001" ) then
            test_data(i) <= "1000" & std_logic_vector(to_unsigned(i,8)) & "0001" & bco(15 downto 0);
          else
            test_data(i) <= "0000" & std_logic_vector(to_unsigned(i,8)) & "0001" & bco(15 downto 0);
          end if;
          test_data_valid(i) <= '1';
        end if;
      end loop;
      for i in 0 to 23 loop
        if ( test_fifo_read(i) = '1' ) then
          if ( test_data(i)(31) = '1' ) then
            test_data_valid(i) <= '0';
          else
            count := std_logic_vector(unsigned(test_data(i)(19 downto 16))+1);
            if ( test_csr(3 downto 0) = count ) then
              test_data(i) <= "1000" & std_logic_vector(to_unsigned(i,8)) & count & bco(15 downto 0);
            else
              test_data(i) <= "0000" & std_logic_vector(to_unsigned(i,8)) & count & bco(15 downto 0);
            end if;
            test_data_valid(i) <= '1';
          end if;
        end if;
      end loop;
    end if;
  end process;

  process ( busclk )
    variable onebit : std_logic;
  begin
    if ( busclk'event and busclk= '1' ) then

      simulated_lv1 <= '0';
      test_buffer_status_r <= test_buffer_status;
      test_stream_status_r <= test_stream_status;
      doing_buffer_clear_r <= doing_buffer_clear;
      if ( do_buffer_clear = '1' and doing_buffer_clear_r = '1' ) then
        do_buffer_clear <= '0';
      end if;
      doing_buffer_dump_r <= doing_buffer_dump;
      if ( do_buffer_dump = '1' and doing_buffer_dump_r = '1' ) then
        do_buffer_dump <= '0';
      end if;

      if ( iobus.io_addr_strobe = '1' and masked_address = base_address ) then
        iobus_ready <= '1';
        if ( iobus.io_write_strobe = '1' ) then
          case iobus.io_address(15 downto 0) is
            when address_test_csr =>
              test_csr <= iobus.io_write_data(31) & '0' &
                          iobus.io_write_data(29 downto 0);
              simulated_lv1 <= iobus.io_write_data(30);
              periodic_lv1 <= iobus.io_write_data(29);
            when address_test_mask =>
              test_readout_mask <= iobus.io_write_data;
            when address_period =>
              test_period <= iobus.io_write_data;
            when address_test_buffer_csr =>
              test_buffer_csr <= iobus.io_write_data;
              buffer_clear <= iobus.io_write_data(nbuf-1 downto 0);
              onebit := '0';
              for i in 0 to nbuf-1 loop
                if ( iobus.io_write_data(i) = '1' ) then
                  onebit := '1';
                  exit;
                end if;
              end loop;
              if ( onebit = '1' and doing_buffer_clear_r = '0' ) then
                do_buffer_clear <= '1';
              end if;
            when address_test_stream_csr =>
              test_stream_csr <= iobus.io_write_data;
              if ( doing_buffer_dump_r = '0' ) then
                do_buffer_dump <= iobus.io_write_data(31);
              end if;
            when others =>
          end case;
        end if;

        if ( iobus.io_read_strobe = '1' ) then
          case iobus.io_address(15 downto 0) is
            when address_test_csr =>
              latched_data <= test_csr; 
            when address_test_mask =>
              latched_data <= test_readout_mask;
            when address_period =>
              latched_data <= test_period;
            when address_test_buffer_csr =>
              latched_data <= zero(31 downto nbuf) & test_buffer_status_r;
            when address_test_dumping_csr =>
              latched_data <= zero(31 downto nbuf) & test_stream_status_r;
            when address_test_stream_csr =>
              latched_data <= test_stream_csr;
            when others =>
          end case;
        end if;
      else
        iobus_ready <= '0';
        latched_data <= ( others => '0' );
      end if;
    end if;
  end process;

  masked_address <= iobus.io_address(31 downto 16) and address_mask;
  write_data <= latched_data;

  process ( busclk ) begin
    if ( busclk'event and busclk = '1' ) then
      do_buffer_clear_r <= do_buffer_clear;
      buffer_clear_r <= buffer_reset(buffer_clear_r'left downto 0);
      if ( do_buffer_clear_r = '1' and doing_buffer_clear = '0' ) then
        doing_buffer_clear <= '1';
        buffer_clear_r <= buffer_clear;
      end if;
      if ( doing_buffer_clear = '1' and do_buffer_clear_r = '0' ) then
        doing_buffer_clear <= '0';
      end if;
    end if;
  end process;

  process ( xaui_stream_clk )
    variable onebit : std_logic;
  begin
    if ( xaui_stream_clk'event and xaui_stream_clk = '1' ) then
      buffer_number <= test_stream_csr(buffer_number'left downto 0);
      stream_buffer_r <= test_stream_status;
      dump_buffer <= '0';
      if ( do_buffer_dump = '1' and doing_buffer_dump = '0' ) then
        dump_buffer <= '1';
      end if;
      onebit := '0';
      for i in 0 to nbuf-1 loop
        if ( stream_buffer_r(i) = '1' ) then
          onebit := '1';
          exit;
        end if;
      end loop;
      doing_buffer_dump <= onebit;
    end if;
  end process;

  process ( busclk ) begin
    if ( busclk'event and busclk = '1' ) then
      if ( unsigned(delay) > unsigned(test_period) ) then
        delay <= ( others => '0' );
      else
        delay <= std_logic_vector(unsigned(delay)+1);
      end if;
    end if;
  end process;

  synthetic_lv1 <= simulated_lv1 when periodic_lv1 = '0' else
                   '1' when delay = x"00000000" else '0';

end RTL;
