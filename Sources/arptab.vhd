----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:38:23 06/15/2013 
-- Design Name: 
-- Module Name:    arptab - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity arptab is
  generic ( size : natural := 16 );
    port ( reset : in std_logic;
           clk : in std_logic;
           read_strobe : in std_logic;
           write_strobe : in std_logic;
           my_ip_address : in std_logic_vector(31 downto 0);
           gw_ip_address : in std_logic_vector(31 downto 0);
           my_netmask : in std_logic_vector(31 downto 0);
           load_ip_addr : in std_logic_vector(31 downto 0);
           load_hw_addr : in std_logic_vector(47 downto 0);
           lookup_ip_addr : in std_logic_vector(31 downto 0);
           target_ip_addr : out std_logic_vector(31 downto 0);
           lookup_hw_addr : out std_logic_vector(47 downto 0);
           found : out std_logic;
           missing : out std_logic;
           entries : out std_logic_vector(7 downto 0);
           index : in std_logic_vector(7 downto 0);
           table_ip_addr : out std_logic_vector(31 downto 0);
           table_hw_addr : out std_logic_vector(47 downto 0);
           table_ref_count : out std_logic_vector(31 downto 0)
         );
end arptab;

architecture Behavioral of arptab is
  type arpent_t is
    record
      ip_addr : std_logic_vector(31 downto 0);
      hw_addr : std_logic_vector(47 downto 0);
      refcount : unsigned(31 downto 0);
    end record;
  type arptab_entries_t is array(integer range 0 to size-1) of arpent_t;
  type read_state_t is ( Idle,
                         Searching,
                         Done
                       );
  TYPE write_state_t IS ( Idle,
                          Searching,
                          Done
                        );
  signal read_state : read_state_t := Idle;
  signal write_state : write_state_t := Idle;

--
--  signal table : arptab_entries_t := ( others => ( x"00000000", x"000000000000", x"00000000" ) );
--  signal count : integer range 0 to size := 0;
--
--
--  These pre-defined constants are mainly for debugging but do tend to
--  decrease the time before valid packets can be sent, provided they truly
--  reflect the devices on the network.
--
  signal table : arptab_entries_t := ( 0 => ( x"c0a828fa", x"00133a07f441", x"00000000" ),
                                       1 => ( x"c0a82ad4", x"00133a082f41", x"00000000" ),
                                       2 => ( x"c0a8287a", x"00133a081c67", x"00000000" ),
                                       others => ( x"00000000", x"000000000000", x"00000000" ) );
  signal count : integer range 0 to size := 3;

  signal read_index : integer range 0 to size;
  signal current_index : integer range 0 to size;
  signal write_index : integer range 0 to size := size;
  signal key : std_logic_vector(31 downto 0);
  signal broadcast : std_logic;
  signal tisfound : std_logic;
  signal tisntfound : std_logic;
  signal new_ip_addr : std_logic_vector(31 downto 0);
  signal new_hw_addr : std_logic_vector(47 downto 0);
  signal dest_ip_addr : std_logic_vector(31 downto 0);
  signal my_network : std_logic_vector(31 downto 0);
  signal target_network : std_logic_vector(31 downto 0);

  signal my_ip_address_r : std_logic_vector(31 downto 0);
  signal gw_ip_address_r : std_logic_vector(31 downto 0);
  signal my_netmask_r : std_logic_vector(31 downto 0);

  signal arptab_entry : arpent_t := ( x"00000000", x"000000000000", x"00000000" );

begin

  process ( clk ) begin
    if ( clk'event and clk = '1' ) then
      if ( tisfound = '0' ) then
        arptab_entry <= table(read_index);
        current_index <= read_index;
      end if;
    end if;
  end process;

  process ( clk, reset, read_strobe, write_strobe )
    variable i : integer range 0 to 255;
  begin
    if ( clk'event and clk = '1' ) then
      if ( reset = '1' ) then
       found <= '0';
       missing <= '0';
      else
        case read_state is
          when Idle =>
            if ( read_strobe = '1' ) then
              key <= dest_ip_addr;
              read_index <= 0;
              found <= '0';
              missing <= '0';
              read_state <= Searching;
            end if;
          when Searching =>
            if ( broadcast = '1' ) then
              lookup_hw_addr <= x"ffffffffffff";
              target_ip_addr <= key;
              read_state <= Done;
            elsif ( tisfound = '1' ) then
              lookup_hw_addr <= arptab_entry.hw_addr;
              target_ip_addr <= arptab_entry.ip_addr;
              read_state <= Done;
            elsif ( tisntfound = '1' ) then
              lookup_hw_addr <= x"ffffffffffff";
              target_ip_addr <= x"ffffffff";
              read_state <= Done;
            else
              lookup_hw_addr <= x"000000000000";
              target_ip_addr <= x"00000000";
              read_index <= read_index + 1;
            end if; 
          when Done =>
            if ( broadcast = '1' ) then
              found <= '1';
              missing <= '0';
            else
              found <= tisfound;
              missing <= tisntfound;
            end if;
            if ( read_strobe = '0' ) then
              read_state <= Idle;
            end if;
        end case;
  
        case write_state is
          when Idle =>
            if ( write_strobe = '1' ) then
              new_ip_addr <= load_ip_addr;
              new_hw_addr <= load_hw_addr;
              write_index <= 0;
              write_state <= Searching;
            end if;
          when Searching =>
            if ( write_index = size ) then
              write_state <= Done;       -- Quietly fail to insert entry
            elsif ( write_index = count ) then
              table(write_index).ip_addr <= new_ip_addr;
              table(write_index).hw_addr <= new_hw_addr;
              table(write_index).refcount <= ( others => '0' );
              count <= count + 1;
              write_state <= Done;
            elsif ( table(write_index).ip_addr = new_ip_addr ) then
              table(write_index).hw_addr <= new_hw_addr;
              write_state <= Done;
            else
              write_index <= write_index + 1;
            end if;
          when Done =>
            if ( write_strobe = '0' ) then
              write_state <= Idle;
            end if;
        end case;

        i := to_integer(unsigned(index));
        table_ip_addr <= table(i).ip_addr;
        table_hw_addr <= table(i).hw_addr;
        table_ref_count <= std_logic_vector(table(i).refcount);
      end if;
      my_ip_address_r <= my_ip_address;
      my_netmask_r <= my_netmask;
      gw_ip_address_r <= gw_ip_address;
    end if;
  end process;

  entries <= std_logic_vector(to_unsigned(count,8));
  broadcast <= '1' when ( key or my_netmask_r ) = x"ffffffff" else '0';
  tisfound <= '1' when arptab_entry.ip_addr = key else '0';
  tisntfound <= '1' when read_index = count else '0';

  my_network <= my_ip_address_r and my_netmask_r;
  target_network <= lookup_ip_addr and my_netmask_r;
  dest_ip_addr <= lookup_ip_addr when my_network = target_network else gw_ip_address_r;

end Behavioral;
