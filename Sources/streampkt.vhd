--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    11:50:00 09/08/2016 
-- Design Name:    amc502
-- Module Name:    streampkt - RTL
-- Project Name:   AMC502
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Streams UDP packets from buffer pool
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

entity streampkt is
  generic ( id : integer := 0 );
  port (
    reset : in std_logic;
    clk : in std_logic;
    strobe : in std_logic;
    busy : out std_logic;
    saddr : in std_logic_vector(31 downto 0);
    daddr : in std_logic_vector(31 downto 0);
    sport : in std_logic_vector(15 downto 0);
    dport : in std_logic_vector(15 downto 0);
   
    buffer_length : in std_logic_vector(15 downto 0);
    buffer_cksum : in std_logic_vector(15 downto 0);
    buffer_rden : out std_logic;
    buffer_data : in std_logic_vector(7 downto 0);

    arp_strobe : out std_logic;
    arptab_found : in std_logic;
    arptab_missing : in std_logic;
    issue_arp_request : out std_logic;
    protocol : out std_logic_vector(7 downto 0);
    length : out std_logic_vector(15 downto 0);
    dout : out std_logic_vector(7 downto 0);
    request : out std_logic;
    enable : in std_logic_vector(3 downto 0)
  );
end streampkt;

architecture RTL of streampkt is
  type State_t is ( Idle,
                    Arping,
                    MoreArping,
                    ArpRequestWait,
                    Arped,
                    Checksum0,
                    Checksum1,
                    Checksum2,
                    Checksum3,
                    Checksum4,
                    Checksum5,
                    Checksum6,
                    Checksum7,
                    Checksum8,
                    Checksum9,
                    Checksum10,
                    Checksum11,
                    Checksum12,
                    Header,
                    Sport1,
                    Dport0,
                    Dport1,
                    Length0,
                    Length1,
                    Udp_checksum0,
                    Udp_checksum1,
                    Data,
                    Done
                  );

  signal state : State_t := Idle;
  signal arp_request : std_logic;
  signal udp_length : std_logic_vector(15 downto 0);
  signal count : unsigned(15 downto 0);
  signal latched_strobe : std_logic;
  signal cksum_input : std_logic_vector(15 downto 0);
  signal udp_cksum : std_logic_vector(15 downto 0) := ( others => '0' );
  signal carry_low : std_logic;
  signal carry_high : std_logic;
  signal cksum_enable : std_logic;
  signal cksum_clear : std_logic;
  signal arp_wait_counter : unsigned(20 downto 0);  -- about 10 ms
  signal triedonce : std_logic;

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

  sum_low : add8
  port map (
    a => cksum_input(7 downto 0),
    b => udp_cksum(7 downto 0),
    s => udp_cksum(7 downto 0),
    clk => clk,
    ce => cksum_enable,
    sclr => cksum_clear,
    c_out => carry_low,
    c_in => carry_high
  );

  sum_high : add8
  port map (
    a => cksum_input(15 downto 8),
    b => udp_cksum(15 downto 8),
    s => udp_cksum(15 downto 8),
    clk => clk,
    ce => cksum_enable,
    sclr => cksum_clear,
    c_out => carry_high,
    c_in => carry_low
  );

  process ( clk, reset, strobe ) begin
    if ( clk'event and clk = '1' ) then     -- sample data on falling edge of clock
      if ( reset = '1' ) then
        dout <= x"77";   -- we should never see this
        request <= '0';
        cksum_clear <= '1';
        cksum_enable <= '0';
        arp_strobe <= '0';
        arp_request <= '0'; 
        buffer_rden <= '0';
        state <= Idle;
      else
        case state is
          when Idle =>
            if ( strobe = '1' ) then     -- retrieve hw address from arp table or issue an arp request
              arp_strobe <= '1';         -- arptab samples on the rising edge, so it is okay to drive this here
              arp_request <= '0'; 
              cksum_clear <= '1';
              cksum_enable <= '0';
              buffer_rden <= '0';
              arp_wait_counter <= ( others => '0' );
              triedonce <= '0';
              state <= Arping;
            else
              arp_request <= '0'; 
              arp_strobe <= '0';
              request <= '0';
              cksum_clear <= '1';
              cksum_enable <= '0';
              buffer_rden <= '0';
              arp_wait_counter <= ( others => '0' );
              triedonce <= '0';
            end if;
          when Arping =>
            state <= MoreArping;   -- Extra cycle to allow arp lookup to clear flags and begin
          when MoreArping =>
            if ( arptab_found = '1' ) then
              arp_request <= '0'; 
              state <= Arped;
            elsif ( arptab_missing = '1' ) then
              if ( triedonce = '1' ) then
                state <= Done;
              else
                arp_request <= '1';
                state <= ArpRequestWait;
              end if;
            end if;
           when ArpRequestWait =>
            if ( arp_wait_counter(1) = '1' ) then
              arp_request <= '0';
            end if;
            if ( arp_wait_counter(arp_wait_counter'left) = '1' ) then
              triedonce <= '1';
              arp_wait_counter <= ( others => '0' );
              state <= Arping;
            end if;
            arp_wait_counter <= arp_wait_counter + 1;
          when Arped =>
            arp_strobe <= '0';
            request <= '1';
            count <= "000" & unsigned(buffer_length(12 downto 0)) - 2;
            state <= Checksum0;
          when Checksum0 =>
            cksum_clear <= '0';
            cksum_enable <= '1';
            cksum_input <= buffer_cksum;
            state <= Checksum1;
          when Checksum1 =>
            cksum_input <= udp_length;
            state <= Checksum2;
          when Checksum2 =>
            cksum_input <= dport;
            state <= Checksum3;
          when Checksum3 =>
            cksum_input <= sport;
            state <= Checksum4;
          when Checksum4 =>
            cksum_input <= udp_length;
            state <= Checksum5;
          when Checksum5 =>
            cksum_input <= x"0011";
            state <= Checksum6;
          when Checksum6 =>
            cksum_input <= daddr(15 downto 0);
            state <= Checksum7;
          when Checksum7 =>
            cksum_input <= daddr(31 downto 16);
            state <= Checksum8;
          when Checksum8 =>
            cksum_input <= saddr(15 downto 0);
            state <= Checksum9;
          when Checksum9 =>
            cksum_input <= saddr(31 downto 16);
            state <= Checksum10;
          when Checksum10 =>
            cksum_input <= x"0000";
            state <= Checksum11;
          when Checksum11 =>
            state <= Checksum12;
          when Checksum12 =>
            state <= Header;
          when Header =>      --  We wait here until the header has been sent and the request acknowledged
            cksum_enable <= '0';
            dout <= sport(15 downto 8);
            if ( to_integer(unsigned(enable)) = id ) then
              dout <= sport(7 downto 0);
              state <= Sport1;
            end if;
          when Sport1 =>
            dout <= dport(15 downto 8);
            state <= Dport0;
          when Dport0 =>
            dout <= dport(7 downto 0);
            state <= Dport1;
          when Dport1 =>
            dout <= udp_length(15 downto 8);
            state <= Length0;
          when Length0 =>
            dout <= udp_length(7 downto 0);
            state <= Length1;
            buffer_rden <= '0';
          when Length1 =>
            dout <= not udp_cksum(15 downto 8);
            state <= Udp_checksum0;
            buffer_rden <= '1'; -- Acquire address 0, set address = 1
          when Udp_checksum0 =>
            dout <= not udp_cksum(7 downto 0);
            buffer_rden <= '1'; -- output address 0, acquire address 1, set address = 2
            if ( count = 0 ) then
              state <= Done;
            else
              state <= Udp_checksum1;
            end if;
          when Udp_checksum1 =>
            dout <= buffer_data;  -- Latch address 0, advance address to 3
            buffer_rden <= '1';
            state <= Data;
          when Data =>
            dout <= buffer_data; -- Latch address n, acquire address n+1, advance address to n+2
            if ( count = 0 ) then
              buffer_rden <= '0';
              state <= Done;
            else
              buffer_rden <= '1';
              count <= count - 1;
            end if;
          when Done =>
            request <= '0';
            buffer_rden <= '0';
            if ( strobe = '0' ) then
              cksum_clear <= '0';
              state <= Idle;
            end if;
-- Not sure how we would end up here, but try to go back to Idle just in case...
          when others =>
            state <= Idle;
        end case;
      end if;
    end if;
  end process;

--  this counts the payload, the 20 byte ip header + 8 bytes for the udp header 
  length <= "000" & std_logic_vector(unsigned(buffer_length(12 downto 0))+28);
--  this counts the payload + 8 bytes for the udp header 
  udp_length <= "000" & std_logic_vector(unsigned(buffer_length(12 downto 0))+8);
  protocol <= x"11";
  busy <= '0' when state = Idle else '1';
  issue_arp_request <= arp_request;

end RTL;
