--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    08:44:16 06/06/2013 
-- Design Name:    stib
-- Module Name:    arprep - RTL
-- Project Name:   STIB firmware
-- Target Devices: xc4vlx25ff668-10
-- Tool versions:  ISE 14.4 / 14.6
-- Description:    Sends ARP reply packet
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

entity arprep is
  generic ( id : integer := 0 );
  port ( reset : in std_logic;
         clk : in std_logic;
         strobe : in std_logic;
         src_ha : in std_logic_vector(47 downto 0);
         src_ip : in std_logic_vector(31 downto 0);
         dst_ha : in std_logic_vector(47 downto 0);
         dst_ip : in std_logic_vector(31 downto 0);
         dout : out std_logic_vector(7 downto 0);
         request : out std_logic;
         enable : in std_logic_vector(3 downto 0)
       );
end arprep;

architecture RTL of arprep is
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
                    Pad0, Pad1, Pad2, Pad3, Pad4, Pad5, Pad6, Pad7, Pad8, Pad9, Pad10, Pad11, Pad12,
                    Pad13, Pad14, Pad15, Pad16, Pad17,
                    Done
                  );

  signal state : State_t := Idle;
  signal matched_enable : std_logic;
begin

  process ( clk, reset ) begin
    if ( clk'event and clk = '1' ) then     -- data is stable on the rising edge.
      if ( reset = '1' ) then
        request <= '0';
        dout <= x"00";
        state <= Idle;
      else
        case state is
          when Idle =>
            if ( strobe = '1' ) then
              request <= '1';
              dout <= x"08"; 
              state <= Frame_header;
            end if;
          when Frame_header =>
            if ( matched_enable = '1' ) then
              dout <= x"06";
              state <= Ether_type0;
            end if;
          when Ether_type0 =>
            dout <= x"00";
            state <= Ether_type1;
          when Ether_type1 =>
            dout <= x"01";
            state <= Hardware_type0;
          when Hardware_type0 =>
            dout <= x"08";
            state <= Hardware_type1;
          when Hardware_type1 =>
            dout <= x"00";
            state <= Protocol_type0;
          when Protocol_type0 =>
            dout <= x"06";
            state <= Protocol_type1;
          when Protocol_type1 =>
            dout <= x"04";
            state <= HA_length;
          when HA_length =>
            dout <= x"00";
            state <= PA_length;
          when PA_length =>
            dout <= x"02";
            state <= Operation0;
          when Operation0 =>
            dout <= src_ha(47 downto 40);
            state <= Operation1;
          when Operation1 =>
            dout <= src_ha(39 downto 32);
            state <= Source_ha_0;
          when Source_ha_0 =>
            dout <= src_ha(31 downto 24);
            state <= Source_ha_1;
          when Source_ha_1 =>
            dout <= src_ha(23 downto 16);
            state <= Source_ha_2;
          when Source_ha_2 =>
            dout <= src_ha(15 downto 8);
            state <= Source_ha_3;
          when Source_ha_3 =>
            dout <= src_ha(7 downto 0);
            state <= Source_ha_4;
          when Source_ha_4 =>
            dout <= src_ip(31 downto 24);
            state <= Source_ha_5;
          when Source_ha_5 =>
            dout <= src_ip(23 downto 16);
            state <= Source_ip_0;
          when Source_ip_0 =>
            dout <= src_ip(15 downto 8);
            state <= Source_ip_1;
          when Source_ip_1 =>
            dout <= src_ip(7 downto 0);
            state <= Source_ip_2;
          when Source_ip_2 =>
            dout <= dst_ha(47 downto 40);
            state <= Source_ip_3;
          when Source_ip_3 =>
            dout <= dst_ha(39 downto 32);
            state <= Target_ha_0;
          when Target_ha_0 =>
            dout <= dst_ha(31 downto 24);
            state <= Target_ha_1;
          when Target_ha_1 =>
            dout <= dst_ha(23 downto 16);
            state <= Target_ha_2;
          when Target_ha_2 =>
            dout <= dst_ha(15 downto 8);
            state <= Target_ha_3;
          when Target_ha_3 =>
            dout <= dst_ha(7 downto 0);
            state <= Target_ha_4;
          when Target_ha_4 =>
            dout <= dst_ip(31 downto 24);
            state <= Target_ha_5;
          when Target_ha_5 =>
            dout <= dst_ip(23 downto 16);
            state <= Target_ip_0;
          when Target_ip_0 =>
            dout <= dst_ip(15 downto 8);
            state <= Target_ip_1;
          when Target_ip_1 =>
            dout <= dst_ip(7 downto 0);
            state <= Target_ip_2;
          when Target_ip_2 =>
            dout <= x"00";
            state <= Target_ip_3;
          when Target_ip_3 =>
            dout <= x"00";
            state <= Pad0;
          when Pad0 =>
            state <= Pad1;
            dout <= x"00";
          when Pad1 =>
            dout <= x"00";
            state <= Pad2;
          when Pad2 =>
            dout <= x"00";
            state <= Pad3;
          when Pad3 =>
            dout <= x"00";
            state <= Pad4;
          when Pad4 =>
            dout <= x"00";
            state <= Pad5;
          when Pad5 =>
            dout <= x"00";
            state <= Pad6;
          when Pad6 =>
            dout <= x"00";
            state <= Pad7;
          when Pad7 =>
            dout <= x"00";
            state <= Pad8;
          when Pad8 =>
            dout <= x"00";
            state <= Pad9;
          when Pad9 =>
            dout <= x"00";
            state <= Pad10;
          when Pad10 =>
            dout <= x"00";
            state <= Pad11;
          when Pad11 =>
            dout <= x"00";
            state <= Pad12;
          when Pad12 =>
            dout <= x"00";
            state <= Pad13;
          when Pad13 =>
            dout <= x"00";
            state <= Pad14;
          when Pad14 =>
            dout <= x"00";
            state <= Pad15;
          when Pad15 =>
            dout <= x"00";
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
