--------------------------------------------------------------------------------
--
-- Company:
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    16:52:05 10/10/2016 
-- Design Name:    amc502
-- Module Name:    xaui_arbiter - RTL
-- Project Name:   
-- Target Devices: Kintex-7 family
-- Tool versions:  Vivado 2016.1
-- Description:    Grants access to the 10GbE interface from multiple sources
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

entity xaui_arbiter is
  generic ( n : integer := 8 );
  port (
    reset : in std_logic;
    clk : in std_logic;
    request : in std_logic_vector(n-1 downto 0);
    grant : out std_logic_vector(n-1 downto 0)
  );
end xaui_arbiter;

architecture Behavioral of xaui_arbiter is

  signal granted : std_logic_vector(n-1 downto 0) := ( others => '0' );

begin

  process ( clk, reset )
    variable iwait : integer range 0 to n-1;
    variable waiting : boolean;
    variable iwant : integer range 0 to n-1;
    variable wanting : boolean;
  begin
    if ( clk'event and clk = '1' ) then     -- data is valid on the rising edge
      if ( reset = '1' ) then
        granted <= ( others => '0' );
      else
        waiting := false;
        wanting := false;
        for i in 0 to n-1 loop
          if ( granted(i) = '1' ) then
            if ( not waiting ) then
              waiting := true;
              iwait := i;
            end if;
          end if;
          if ( request(i) = '1' ) then
            if ( not wanting ) then
              wanting := true;
              iwant := i;
            end if;
          end if;
        end loop;
        if ( waiting ) then
          if ( request(iwait) = '0' ) then
            granted(iwait) <= '0';
          end if;
        elsif ( wanting ) then
          granted(iwant) <= '1';
        end if;
      end if;
      grant <= granted;
    end if;
  end process;

end Behavioral;
