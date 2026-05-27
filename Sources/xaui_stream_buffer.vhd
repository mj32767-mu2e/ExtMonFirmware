----------------------------------------------------------------------------------
-- Company:   Purdue University Dept. of Physics and Astronomy
-- Engineer:  Matthew Jones
-- 
-- Create Date: 12/25/2018 07:22:39 AM
-- Design Name: 
-- Module Name: xgbe_stream_buffer - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
--   This is a tricky but critical piece of code.  Here is how it must
--   work:
--
--   The write process puts data into the buffer on the rising edge of clk_a
--   when wen_a is asserted.  When an entire frame has been put into the buffer,
--   strobe_a is asserted.  The rising edge of strobe_a will frame the data and
--   no further data can be added until strobe_a is deasserted again.
--
--   The test-bench for the write process should put data in, verify that the
--   free status indicator is updated correctly and that the data is removed
--   correctly.
--   
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xaui_stream_buffer is
  generic (
    index : integer := 0
  );
  port (
    rst : in std_logic;
    clk_a : in std_logic;
    wen_a : in std_logic;
    din_a : in std_logic_vector(63 downto 0);
    strobe_a : in std_logic;
    clk_b : in std_logic;
    dv_b : out std_logic;
    dout_b : out std_logic_vector(63 downto 0);
    rden_b : in std_logic;
    done_b : out std_logic;
    cksum : out std_logic_vector(15 downto 0);
    length : out std_logic_vector(11 downto 0);
    advance : in std_logic;
    free : out std_logic_vector(15 downto 0);
    lost : out std_logic_vector(15 downto 0);
    debug_state : out std_logic_vector(3 downto 0)
  );
end xaui_stream_buffer;

architecture Behavioral of xaui_stream_buffer is

  function add_cksum(
    sum : std_logic_vector(15 downto 0);
    din : std_logic_vector(15 downto 0)
  )
  return std_logic_vector is
    variable next_sum : unsigned(16 downto 0);
  begin
    next_sum := unsigned('0' & din) + unsigned('0' & sum);
    if ( next_sum(16) = '1' ) then
      next_sum := ( "0" & next_sum(15 downto 0) ) + 1;
    end if;
    return std_logic_vector(next_sum(15 downto 0));
  end;

  function nbits( n : integer ) return natural is
    variable i : natural;
  begin
    i := 0;
    while ( 2**i < n ) loop
      i := i + 1;
    end loop;
    return i;
  end function;

  function print_hex_long( v : std_logic_vector(63 downto 0) ) return string is
    variable s : string(1 to 16);
  begin
    for i in 15 downto 0 loop
      case v(4*i+3 downto 4*i) is
      when "0000" =>
        s(16-i) := '0';
      when "0001" =>
        s(16-i) := '1';
      when "0010" =>
        s(16-i) := '2';
      when "0011" =>
        s(16-i) := '3';
      when "0100" =>
        s(16-i) := '4';
      when "0101" =>
        s(16-i) := '5';
      when "0110" =>
        s(16-i) := '6';
      when "0111" =>
        s(16-i) := '7';
      when "1000" =>
        s(16-i) := '8';
      when "1001" =>
        s(16-i) := '9';
      when "1010" =>
        s(16-i) := 'a';
      when "1011" =>
        s(16-i) := 'b';
      when "1100" =>
        s(16-i) := 'c';
      when "1101" =>
        s(16-i) := 'd';
      when "1110" =>
        s(16-i) := 'e';
      when "1111" =>
        s(16-i) := 'f';
      end case;
    end loop;
    return "0x" & s;
  end print_hex_long;

  function print_hex_short( v : std_logic_vector(15 downto 0) ) return string is
    variable s : string(1 to 4);
  begin
    for i in 3 downto 0 loop
      case v(4*i+3 downto 4*i) is
      when "0000" =>
        s(4-i) := '0';
      when "0001" =>
        s(4-i) := '1';
      when "0010" =>
        s(4-i) := '2';
      when "0011" =>
        s(4-i) := '3';
      when "0100" =>
        s(4-i) := '4';
      when "0101" =>
        s(4-i) := '5';
      when "0110" =>
        s(4-i) := '6';
      when "0111" =>
        s(4-i) := '7';
      when "1000" =>
        s(4-i) := '8';
      when "1001" =>
        s(4-i) := '9';
      when "1010" =>
        s(4-i) := 'a';
      when "1011" =>
        s(4-i) := 'b';
      when "1100" =>
        s(4-i) := 'c';
      when "1101" =>
        s(4-i) := 'd';
      when "1110" =>
        s(4-i) := 'e';
      when "1111" =>
        s(4-i) := 'f';
      end case;
    end loop;
    return "0x" & s;
  end print_hex_short;

  component lfsr_n
  generic (
    width : integer := 4
  );
  port (
    rst : in std_logic;
    clk : in std_logic;
    en : in std_logic;
    dout : out std_logic_vector(width-1 downto 0);
    prev : out std_logic_vector(width-1 downto 0)
  );
  end component;

--
--  Each buffer contains bits = 512k bytes arranged in 65536 64-bit words
--
  constant buffer_size : integer := 65536;
  constant pkt_buffer_size : integer := 256;

  constant addr_width : natural := nbits(buffer_size);  -- this will be 16
  constant pkt_addr_width : natural := nbits(pkt_buffer_size);  -- This will be 8

  signal words_free : unsigned(addr_width-1 downto 0) := ( others => '1' );
  signal new_sum12 : std_logic_vector(15 downto 0);
  signal new_sum34 : std_logic_vector(15 downto 0);
  signal sum_1234 : std_logic_vector(15 downto 0) := ( others => '0' );
  signal sum : std_logic_vector(15 downto 0) := ( others => '0' );
  signal len : std_logic_vector(15 downto 0) := ( others => '0' );
  type ram_type is array(buffer_size-1 downto 0) of std_logic_vector(63 downto 0);
  type pkt_ram_type is array(pkt_buffer_size-1 downto 0) of std_logic_vector(31 downto 0);
  signal ram : ram_type;
  signal pkt_ram : pkt_ram_type;
  signal packet_data : std_logic_vector(31 downto 0);

  attribute syn_ramstyle : string;
  attribute syn_ramstyle of ram : signal is "no_rw_check";
  attribute syn_ramstyle of pkt_ram : signal is "no_rw_check";

  signal waddr : std_logic_vector(addr_width-1 downto 0);
  signal raddr : std_logic_vector(addr_width-1 downto 0);
  signal pkt_waddr : std_logic_vector(pkt_addr_width-1 downto 0);
  signal pkt_raddr : std_logic_vector(pkt_addr_width-1 downto 0);
  signal read_data : std_logic_vector(63 downto 0);
  signal count : unsigned(15 downto 0) := ( others => '0' );
  signal minus : unsigned(addr_width-1 downto 0) := ( others => '0' );
  signal subtracted : std_logic := '0';
  signal last_strobe : std_logic := '0';
  signal pkt_ram_we : std_logic_vector(2 downto 0);
  signal pkt_ram_re : std_logic;
  signal ram_we : std_logic;
  signal ram_re : std_logic := '0';

  signal gated_wen_a : std_logic;
  signal clogged : std_logic := '0';
  signal lost_packets : unsigned(15 downto 0) := ( others => '0' );

  type read_state_t is ( Idle, Reading, Done );
  signal read_state : read_state_t := Idle;

  constant lfsr : boolean := false;

  attribute mark_debug : string;
  attribute mark_debug of waddr : signal is "true";
  attribute mark_debug of raddr : signal is "true";
  attribute mark_debug of pkt_waddr : signal is "true";
  attribute mark_debug of pkt_raddr : signal is "true";

begin

--
--  Use Galois LFSR for read and write pointers for fast address increment
--

  g_lfsr: if ( lfsr ) generate
    waddr_imp : lfsr_n
    generic map (
      width => addr_width
    )
    port map (
      rst => rst,
      clk => clk_a,
      en => gated_wen_a,
      dout => waddr,
      prev => open
    );

    raddr_imp : lfsr_n
    generic map (
      width => addr_width
    )
    port map (
      rst => rst,
      clk => clk_b,
      en => ram_re,
      dout => raddr,
      prev => open
    );

    pkt_waddr_imp : lfsr_n
    generic map (
      width => pkt_addr_width
    )
    port map (
      rst => rst,
      clk => clk_a,
      en => pkt_ram_we(0),
      dout => pkt_waddr,
      prev => open
    );

    pkt_raddr_imp : lfsr_n
    generic map (
      width => pkt_addr_width
    )
    port map (
      rst => rst,
      clk => clk_b,
      en => pkt_ram_re,
      dout => pkt_raddr,
      prev => open
    );
  end generate;

  g_linear : if ( not lfsr ) generate
    process ( clk_a, rst, gated_wen_a, pkt_ram_we ) begin
      if ( clk_a'event and clk_a = '1' ) then
        if ( rst = '1' ) then
          waddr <= ( others => '0' );
          pkt_waddr <= ( others => '0' );
        else
          if ( gated_wen_a = '1' ) then
            waddr <= std_logic_vector(unsigned(waddr)+1);
          end if;
          if ( pkt_ram_we(0) = '1' ) then
            pkt_waddr <= std_logic_vector(unsigned(pkt_waddr)+1);
          end if;
        end if;
      end if;
    end process;
    process ( clk_b, rst, ram_re, pkt_ram_re ) begin
      if ( clk_b'event and clk_b = '1' ) then
        if ( rst = '1' ) then
          raddr <= ( others => '0' );
        else
          if ( ram_re = '1' ) then
            raddr <= std_logic_vector(unsigned(raddr)+1);
          end if;
          if ( pkt_ram_re = '1' ) then
            pkt_raddr <= std_logic_vector(unsigned(pkt_raddr)+1);
          end if;
        end if;
      end if;
    end process;
  end generate;

--
--  Infer dual port RAM for data
--

  process ( clk_a ) begin
    if ( clk_a'event and clk_a = '1' ) then
      if ( ram_we = '1' ) then
        ram(to_integer(unsigned(waddr))) <= din_a;
        report "[" & integer'image(index) & "] Wrote to address " &
               integer'image(to_integer(unsigned(waddr)));
      end if;
    end if;
  end process;

  process ( clk_b ) begin
    if ( clk_b'event and clk_b = '1' ) then
      read_data <= ram(to_integer(unsigned(raddr)));
    end if;
  end process;

--
--  Infer dual port RAM for checksum/length
--

  process ( clk_a ) begin
    if ( clk_a'event and clk_a = '1' ) then
      if ( pkt_ram_we(0) = '1' ) then
        report "[" & integer'image(index) &
               "] Writing length + checksum to RAM.";
        pkt_ram(to_integer(unsigned(pkt_waddr))) <= len & sum;
      end if;
    end if;
  end process;

  process ( clk_b ) begin
    if ( clk_b'event and clk_b = '1' ) then
      packet_data <= pkt_ram(to_integer(unsigned(pkt_raddr)));
    end if;
  end process;

--
--  Write process
--

  process ( rst, clk_a, gated_wen_a, strobe_a )
    variable new_sum : std_logic_vector(15 downto 0);
    variable empty : unsigned(words_free'left downto 0);
    variable add : unsigned(0 downto 0);
    variable subtract : unsigned(words_free'left downto 0);
  begin
    if ( clk_a'event and clk_a = '1' ) then
      if ( rst = '1' ) then
        sum <= ( others => '0' );
        sum_1234 <= ( others => '0' );
        len <= ( others => '0' );
        words_free <= ( others => '1' );
        lost_packets <= ( others => '0' );
      else
        empty := words_free;
        add := "0";

--
--   Process one 64-bit word being written to the FIFO...
--
        if ( gated_wen_a = '1' ) then
          report "[" & integer'image(index) & "] UDP data word = " &
                 print_hex_long(din_a);
--
--  Update the 16-bit checksum for the UDP data.  Remember that the bytes
--  come out in the reverse order.
--
          new_sum12 <= add_cksum(din_a(7 downto 0) & din_a(15 downto 8),
                                 din_a(23 downto 16) & din_a(31 downto 24));
          new_sum34 <= add_cksum(din_a(39 downto 32) & din_a(47 downto 40),
                                 din_a(55 downto 48) & din_a(63 downto 56));
          report "[" & integer'image(index) & "] New buffer sum = " &
                 print_hex_short(new_sum);
          len <= std_logic_vector(unsigned(len)+8);   -- We write 8 bytes at a time
          add := "1";
        else
          new_sum12 <= ( others => '0' );
          new_sum34 <= ( others => '0' );
        end if;
        if ( subtracted = '0' and minus /= x"0000" ) then
          subtract := minus;
          subtracted <= '1';
        elsif ( minus = x"0000" ) then
          subtracted <= '0';
          subtract := ( others => '0' );
        else
          subtract := ( others => '0' );
        end if;
        empty := empty - add + subtract;
        words_free <= empty;
        sum_1234 <= add_cksum(new_sum12,new_sum34);
        sum <= add_cksum(sum,sum_1234);
      end if;
--
--  Process the end of packet
--
      last_strobe <= strobe_a;
      if ( strobe_a = '1' and last_strobe = '0' ) then
        report "[" & integer'image(index) &
               "] Finished writing packet - advancing write pointer.";
        pkt_ram_we(pkt_ram_we'left) <= '1';
      else
        pkt_ram_we(pkt_ram_we'left) <= '0';
      end if;
      pkt_ram_we(pkt_ram_we'left-1 downto 0) <= pkt_ram_we(pkt_ram_we'left downto 1);
      if ( pkt_ram_we(0) = '1' ) then
        report "[" & integer'image(index) &
               "] Resetting sum+length.";
        sum <= ( others => '0' );
        len <= ( others => '0' );
      end if;
      free(words_free'left downto 0) <= std_logic_vector(words_free);
    end if;
  end process;

--
--  Process reading from the FIFO
--
  process ( clk_b ) begin
    if ( clk_b'event and clk_b = '1' ) then
      if ( rst = '1' ) then
        done_b <= '0';
        pkt_ram_re <= '0';
      else
        case read_state is
        when Idle =>
          debug_state(1 downto 0) <= "00";
          done_b <= '0';
          pkt_ram_re <= '0';
          count <= unsigned(packet_data(31 downto 16));
          if ( rden_b = '1' ) then
            report "[" & integer'image(index) & "] First read from address " &
                   integer'image(to_integer(unsigned(raddr))) & " ram_re = " &
                   std_logic'image(ram_re) & ", rden_b = " &
                   std_logic'image(rden_b);
            read_state <= Reading;
          else
            read_state <= Idle;
          end if;
        when Reading =>
          debug_state(1 downto 0) <= "01";
          report "[" & integer'image(index) & "] Reading from address " &
                 integer'image(to_integer(unsigned(raddr))) &
                 ", count = " & integer'image(to_integer(count));
          pkt_ram_re <= '0';
          if ( subtracted = '1' ) then
            minus <= ( others => '0' );
          end if;
          if ( to_integer(count) = 8 ) then
            read_state <= Done;
            done_b <= '1';
            if ( subtracted = '0' ) then
              minus <= unsigned(packet_data(31 downto 16)) / 8;
            end if;
          else
            done_b <= '0';
            count <= count - 8;   -- We suck out 8 bytes at a time
            read_state <= Reading;
          end if;
        when Done =>
          debug_state(1 downto 0) <= "10";
          done_b <= '1';
          if ( advance = '1' ) then
            report "[" & integer'image(index) &
                   "] Asserting packet read enable.";
            report "pkt_raddr = " & integer'image(to_integer(unsigned(pkt_raddr))) &
                   ", pkt_waddr = " & integer'image(to_integer(unsigned(pkt_waddr)));
            pkt_ram_re <= '1';
            read_state <= Idle;
          else
            pkt_ram_re <= '0';
          end if;
        end case;
      end if;
    end if;
  end process;

  gated_wen_a <= wen_a when clogged = '0' else '0';
  ram_we <= gated_wen_a;
  ram_re <= rden_b when read_state /= Done else '0';
  dv_b <= '1' when pkt_waddr /= pkt_raddr and count /= 8 else '0';

  lost <= std_logic_vector(lost_packets);

  dout_b <= read_data;
  cksum <= packet_data(15 downto 0);
  length <= packet_data(27 downto 16);

end Behavioral;
