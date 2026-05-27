--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    08:44:16 06/06/2013 
-- Design Name:    stib
-- Module Name:    arpreq - RTL
-- Project Name:   STIB firmware
-- Target Devices: xc4vlx25ff668-10
-- Tool versions:  ISE 14.4 / 14.6
-- Description:    Sends ARP request packet
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

entity arpreq is
  generic ( id : integer := 0 );
  port ( reset : in std_logic;
         clk : in std_logic;
         strobe : in std_logic;
         src_ha : in std_logic_vector(47 downto 0);
         src_ip : in std_logic_vector(31 downto 0);
         target_ip : in std_logic_vector(31 downto 0);
         my_netmask : in std_logic_vector(31 downto 0);
         gw_ip_address : in std_logic_vector(31 downto 0);
         dout : out std_logic_vector(7 downto 0);
         request : out std_logic;
         enable : in std_logic_vector(3 downto 0)
       );
end arpreq;

architecture RTL of arpreq is
  type State_t is ( Idle,
                    Frame_header, Ether_type0, Ether_type1,
                    Hardware_type0, Hardware_type1,
                    Protocol_type0, Protocol_type1,
                    HA_length, PA_length,
                    Operation0, Operation1,
                    Source_ha_0, Source_ha_1, Source_ha_2, Source_ha_3, Source_ha_4, Source_ha_5,
                    Source_ip_0, Source_ip_1, Source_ip_2, Source_ip_3,
                    Target_ha_0, Target_ha_1, Target_ha_2, Target_ha_3, Target_ha_4, Target_ha_5,
                    Target_ip_0, Target_ip_1, Target_ip_2, Target_ip_3,
                    Pad0, Pad1, Pad2, Pad3, Pad4, Pad5, Pad6, Pad7, Pad8, Pad9, Pad10, Pad11, Pad12, Pad13, Pad14, Pad15, Pad16, Pad17,
                    Done
                  );

  signal state : State_t := Idle;
  signal matched_enable : std_logic;
  signal my_network : std_logic_vector(31 downto 0);
  signal target_network : std_logic_vector(31 downto 0);
  signal request_addr : std_logic_vector(31 downto 0);

begin

  process ( clk, reset ) begin
    if ( clk'event and clk = '1' ) then     -- data is valid on the rising edge
      if ( reset = '1' ) then
        request <= '0';
        dout <= x"22";
        state <= Idle;
      else
        case state is
          when Idle =>
            if ( strobe = '1' ) then
              request <= '1';
              dout <= x"08"; 
              my_network <= my_netmask and gw_ip_address;
              target_network <= my_netmask and target_ip;
              state <= Frame_header;
            else
              request <= '0';
            end if;
          when Frame_header =>
            if ( matched_enable = '1' ) then
              dout <= x"06";
              state <= Ether_type0;
            end if;
          when Ether_type0 =>
            if ( my_network = target_network ) then
              request_addr <= target_ip;
            else
              request_addr <= gw_ip_address;
            end if;
            dout <= x"00";
            state <= Ether_type1;
          when Ether_type1 =>
            dout <= x"01";
            state <= Hardware_type0;
          when Hardware_type0 =>
            dout <= x"08";
            state <= Hardware_type1;
          when hardware_type1 =>
            dout <= x"00";
            state <= Protocol_type0;
          when protocol_type0 =>
            dout <= x"06";
            state <= Protocol_type1;
          when protocol_type1 =>
            dout <= x"04";
            state <= Ha_length;
          when ha_length =>
            dout <= x"00";
            state <= Pa_length;
          when pa_length =>
            dout <= x"01";   -- arp request
            state <= Operation0;
          when operation0 =>
            dout <= src_ha(47 downto 40);
            state <= Operation1;
          when operation1 =>
            dout <= src_ha(39 downto 32);
            state <= Source_ha_0;
          when source_ha_0 =>
            dout <= src_ha(31 downto 24);
            state <= Source_ha_1;
          when source_ha_1 =>
            dout <= src_ha(23 downto 16);
            state <= Source_ha_2;
          when source_ha_2 =>
            dout <= src_ha(15 downto 8);
            state <= Source_ha_3;
          when source_ha_3 =>
            dout <= src_ha(7 downto 0);
            state <= Source_ha_4;
          when source_ha_4 =>
            dout <= src_ip(31 downto 24);
            state <= Source_ha_5;
          when source_ha_5 =>
            dout <= src_ip(23 downto 16);
            state <= Source_ip_0;
          when source_ip_0 =>
            dout <= src_ip(15 downto 8);
            state <= Source_ip_1;
          when source_ip_1 =>
            dout <= src_ip(7 downto 0);
            state <= Source_ip_2;
          when source_ip_2 =>
            dout <= x"00";
            state <= Source_ip_3;
          when source_ip_3 =>
            dout <= x"00";
            state <= Target_ha_0;
          when target_ha_0 =>
            dout <= x"00";
            state <= Target_ha_1;
          when target_ha_1 =>
            dout <= x"00";
            state <= Target_ha_2;
          when target_ha_2 =>
            dout <= x"00";
            state <= Target_ha_3;
          when target_ha_3 =>
            dout <= x"00";
            state <= Target_ha_4;
          when target_ha_4 =>
            dout <= request_addr(31 downto 24);
            state <= Target_ha_5;
          when target_ha_5 =>
            dout <= request_addr(23 downto 16);
            state <= Target_ip_0;
          when target_ip_0 =>
            dout <= request_addr(15 downto 8);
            state <= Target_ip_1;
          when target_ip_1 =>
            dout <= request_addr(7 downto 0);
            state <= Target_ip_2;
          when target_ip_2 =>
            dout <= x"00";
            state <= Target_ip_3;
          when target_ip_3 =>
            dout <= x"00";
            state <= Pad0;
          when pad0 =>
            dout <= x"00";
            state <= Pad1;
          when pad1 =>
            dout <= x"00";
            state <= Pad2;
          when pad2 =>
            dout <= x"00";
            state <= Pad3;
          when pad3 =>
            dout <= x"00";
            state <= Pad4;
          when pad4 =>
            dout <= x"00";
            state <= Pad5;
          when pad5 =>
            dout <= x"00";
            state <= Pad6;
          when pad6 =>
            dout <= x"00";
            state <= Pad7;
          when pad7 =>
            dout <= x"00";
            state <= Pad8;
          when pad8 =>
            dout <= x"00";
            state <= Pad9;
          when pad9 =>
            dout <= x"00";
            state <= Pad10;
          when pad10 =>
            dout <= x"00";
            state <= Pad11;
          when pad11 =>
            dout <= x"00";
            state <= Pad12;
          when pad12 =>
            dout <= x"00";
            state <= Pad13;
          when pad13 =>
            dout <= x"00";
            state <= Pad14;
          when pad14 =>
            dout <= x"00";
            state <= Pad15;
          when pad15 =>
            dout <= x"01";
            state <= Pad16;
          when others =>
            request <= '0';
            if ( strobe = '0' ) then
              state <= Idle;
            end if;
        end case;
      end if;
    end if;
  end process;

  matched_enable <= '1' when to_integer(unsigned(enable)) = id else '0';

end RTL;
