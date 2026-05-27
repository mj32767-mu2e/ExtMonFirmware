----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/15/2016 08:04:39 PM
-- Design Name: 
-- Module Name: sim_gbe_stream - RTL
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
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gbe_stream_buffer is
  port (
    rst : in std_logic;
    clk_a : in std_logic;
    wen_a : in std_logic;
    din_a : in std_logic_vector(31 downto 0);
    strobe_a : in std_logic;
    clk_b : in std_logic;
    dv_b : out std_logic;
    dout_b : out std_logic_vector(7 downto 0);
    rden_b : in std_logic;
    strobe_b : out std_logic;
    cksum : out std_logic_vector(15 downto 0);
    length : out std_logic_vector(15 downto 0);
    free : out std_logic_vector(15 downto 0);
    lost : out std_logic_vector(15 downto 0)
  );
end gbe_stream_buffer;

architecture RTL of gbe_stream_buffer is

 function htons(
    din : std_logic_vector(15 downto 0)
  ) return std_logic_vector is
    variable dout : std_logic_vector(15 downto 0);
  begin
    dout(7 downto 0) := din(15 downto 8);
    dout(15 downto 8) := din(7 downto 0);
    return dout;
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

  constant buffer_size : integer := 65536;
  constant pkt_buffer_size : integer := 512;

  constant addr_width : natural := nbits(buffer_size);
  constant pkt_addr_width : natural := nbits(pkt_buffer_size);

  signal words_free : unsigned(addr_width-1 downto 0) := ( others => '1' );
  signal sum : std_logic_vector(15 downto 0) := ( others => '0' );
  signal len : std_logic_vector(15 downto 0) := ( others => '0' );
  type ram_type is array(buffer_size-1 downto 0) of std_logic_vector(31 downto 0);
  type pkt_ram_type is array(pkt_buffer_size-1 downto 0) of std_logic_vector(31 downto 0);
  signal ram : ram_type;
  signal pkt_ram : pkt_ram_type;
  signal packet_data : std_logic_vector(31 downto 0);

  attribute syn_ramstyle : string;
  attribute syn_ramstyle of ram : signal is "no_rw_check";
  attribute syn_ramstyle of pkt_ram : signal is "no_rw_check";

  signal waddr : std_logic_vector(addr_width-1 downto 0);
  signal raddr : std_logic_vector(addr_width-1 downto 0);
  signal saddr : unsigned(1 downto 0);
  signal pkt_waddr : std_logic_vector(pkt_addr_width-1 downto 0);
  signal pkt_raddr : std_logic_vector(pkt_addr_width-1 downto 0);
  signal read_data : std_logic_vector(31 downto 0);
  signal count : unsigned(15 downto 0) := ( others => '0' );
  signal minus : unsigned(15 downto 0) := ( others => '0' );
  signal subtracted : std_logic := '0';
  signal last_strobe : std_logic := '0';
  signal read_enable : std_logic;
  signal pkt_ram_we : std_logic;
  signal pkt_ram_re : std_logic;
  signal ram_we : std_logic;

  signal gated_wen_a : std_logic;
  signal clogged : std_logic := '0';
  signal lost_packets : unsigned(15 downto 0) := ( others => '0' );

begin

--
--  Use Galois LFSR for read and write pointers for fast address increment
--

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
    en => read_enable,
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
    en => pkt_ram_we,
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

--
--  Infer dual port RAM for data
--

  process ( clk_a ) begin
    if ( clk_a'event and clk_a = '1' ) then
      if ( ram_we = '1' ) then
        ram(to_integer(unsigned(waddr))) <= din_a;
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
      if ( pkt_ram_we = '1' ) then
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

  process ( rst, clk_a )
    variable new_sum : unsigned(18 downto 0);
    variable new_len : unsigned(15 downto 0);
    variable empty : unsigned(words_free'left downto 0);
    variable add : unsigned(0 downto 0);
    variable subtract : unsigned(15 downto 0);
  begin
    if ( clk_a'event and clk_a = '1' ) then
      if ( rst = '1' ) then
        sum <= ( others => '0' );
        len <= ( others => '0' );
        words_free <= ( others => '1' );
        lost_packets <= ( others => '0' );
      else
        empty := words_free;
        add := "0";
        if ( gated_wen_a = '1' ) then
          new_sum := "000" & unsigned(sum);
          new_sum := new_sum + unsigned(htons(din_a(15 downto 0)));
          new_sum := new_sum + unsigned(htons(din_a(31 downto 16)));
          new_sum := "000" & new_sum(15 downto 0) + new_sum(18 downto 16);
          new_sum := "000" & new_sum(15 downto 0) + new_sum(18 downto 16);
          new_len:= unsigned(len)+4;
          sum <= std_logic_vector(new_sum(15 downto 0));
          len <= std_logic_vector(new_len);
          add := "1";
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
      end if;

      if ( pkt_ram_we = '1' ) then
        sum <= ( others => '0' );
        len <= ( others => '0' );
      end if;
      free <= std_logic_vector(words_free);
      last_strobe <= strobe_a;
      if ( last_strobe = '0' and strobe_a = '1' ) then
        if ( words_free(words_free'left) = '0' ) then
          clogged <= '1';
          if ( lost_packets /= x"ffff" ) then
            lost_packets <= lost_packets + 1;
          end if;
        else
          clogged <= '0';
        end if;
      end if;
    end if;
  end process;

  process ( clk_b ) begin
    if ( clk_b'event and clk_b = '1' ) then
      if ( rst = '1' ) then
        dv_b <= '0';
        saddr <= "00";
        strobe_b <= '0';
        pkt_ram_re <= '0';
      else
        if ( pkt_waddr /= pkt_raddr ) then
          dv_b <= '1';
        else
          dv_b <= '0';
        end if;
        if ( rden_b = '1' ) then
          if ( subtracted = '1' ) then
            minus <= ( others => '0' );
          end if;
          if ( to_integer(count) = 0 ) then
            strobe_b <= '0';
            pkt_ram_re <= '0';
            count <= unsigned(packet_data(31 downto 16));
            saddr <= "00";
          else
            count <= count - 1;
            saddr <= saddr + 1;
            if ( to_integer(count) = 1 ) then
              strobe_b <= '1';
              pkt_ram_re <= '1';
              if ( subtracted = '0' ) then
                minus <= unsigned(packet_data(31 downto 16)) / 4;
              end if;
            elsif ( to_integer(count) /= 0 ) then
              strobe_b <= '0';
              pkt_ram_re <= '0';
            end if;
          end if;
        else
          strobe_b <= '0';
          pkt_ram_re <= '0';
          saddr <= "00";
        end if;
      end if;
    end if;
  end process;

  gated_wen_a <= wen_a when clogged = '0' else '0';
  ram_we <= gated_wen_a;
  lost <= std_logic_vector(lost_packets);

  pkt_ram_we <= not clogged when strobe_a = '1' and last_strobe = '0' else '0';
  read_enable <= '1' when rden_b = '1' and saddr = "10" else '0';

  dout_b <= read_data(7 downto 0) when saddr = "00" else
            read_data(15 downto 8) when saddr = "01" else
            read_data(23 downto 16) when saddr = "10" else
            read_data(31 downto 24);
  cksum <= packet_data(15 downto 0);
  length <= packet_data(31 downto 16);

end RTL;
