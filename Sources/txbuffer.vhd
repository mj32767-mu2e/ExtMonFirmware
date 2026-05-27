----------------------------------------------------------------------------------
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    13:03:10 06/09/2016 
-- Design Name:    amc502
-- Package Name:   gbe
-- Project Name:   amc502 firmware
-- Target Devices: xc7k420tffv1156-1
-- Tool versions:  Vivado 2016.1
-- Description:    Defines a dual-port RAM that automatically computes
--                 checksums
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

entity txbuffer is
  port (
    reset : in std_logic;
    clka : in std_logic;
    ena : in std_logic;
    wea : in std_logic_vector(3 downto 0);
    addra : in std_logic_vector(8 downto 0);
    dina : in std_logic_vector(31 downto 0);
    douta : out std_logic_vector(31 downto 0);
    cksum : out std_logic_vector(15 downto 0);
    clkb : in std_logic;
    addrb : in std_logic_vector(10 downto 0);
    doutb : out std_logic_vector(7 downto 0)
  );
end txbuffer;

architecture RTL of txbuffer is

  function htons(
    din : std_logic_vector(15 downto 0)
  ) return std_logic_vector is
    variable dout : std_logic_vector(15 downto 0);
  begin
    dout(7 downto 0) := din(15 downto 8);
    dout(15 downto 8) := din(7 downto 0);
    return dout;
  end;

  signal sum : std_logic_vector(15 downto 0) := ( others => '0' );
  type ram_type is array(511 downto 0) of std_logic_vector(31 downto 0);
  signal ram : ram_type;
begin

  process ( clka )
    variable new_sum : unsigned(18 downto 0);
    variable new_ram : std_logic_vector(31 downto 0);
    variable old_ram : std_logic_vector(31 downto 0);
  begin

    if ( clka'event and clka = '1' ) then
      if ( reset = '1' ) then
        sum <= ( others => '0' );
        cksum <= ( others => '0' );
      elsif ( ena = '1' ) then
        new_sum := "000" & unsigned(sum);
        old_ram := ram(to_integer(unsigned(addra)));
        new_ram := old_ram;
        for i in 0 to 3 loop
          if ( wea(i) = '1' ) then
            new_ram(8*i+7 downto 8*i) := dina(8*i+7 downto 8*i);
          end if;
        end loop;
        new_sum := new_sum - unsigned(htons(old_ram(15 downto 0)));
        new_sum := new_sum + unsigned(htons(new_ram(15 downto 0)));
        new_sum := new_sum - unsigned(htons(old_ram(31 downto 16)));
        new_sum := new_sum + unsigned(htons(new_ram(31 downto 16)));

        if ( new_sum(18) = '0' ) then
          new_sum := "000" & new_sum(15 downto 0) + new_sum(17 downto 16);
        else
          new_sum := "000" & new_sum(15 downto 0) - not new_sum(17 downto 16) - 1;
        end if;
        sum <= std_logic_vector(new_sum(15 downto 0));
        cksum <= std_logic_vector(new_sum(15 downto 0));
        ram(to_integer(unsigned(addra))) <= new_ram;
      else
        douta <= ram(to_integer(unsigned(addra)));    
      end if;
    end if;
  end process;

  process ( clkb )
    variable word : std_logic_vector(31 downto 0);
  begin
    if ( clkb'event and clkb = '1' ) then
      word := ram(to_integer(unsigned(addrb(10 downto 2))));
      case addrb(1 downto 0) is
        when "00" =>
--        doutb <= word(31 downto 24);
          doutb <= word(7 downto 0);
        when "01" =>
--        doutb <= word(23 downto 16);
          doutb <= word(15 downto 8);
        when "10" =>
--        doutb <= word(15 downto 8);
          doutb <= word(23 downto 16);
        when "11" =>
--        doutb <= word(7 downto 0);
          doutb <= word(31 downto 24);
        when others =>
      end case;
    end if;
  end process;

end RTL;
