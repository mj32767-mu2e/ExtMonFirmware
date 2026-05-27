----------------------------------------------------------------------------------
-- Engineer:       Matthew Jones - Purdue University
-- 
-- Create Date:    08:44:16 06/06/2013 
-- Design Name:    stib
-- Module Name:    crc32 - RTL
-- Project Name:   STIB firmware
-- Target Devices: xc4vlx25-ff668-10
-- Tool versions:  ISE 14.4 / 14.6
-- Description:    Calculates the 32-bit Ethernet frame CRC by means of a
--                 look-up table in ROM.
--
--                 CLEAR, CALC and DATA are sampled on the rising edge of CLK
--                 and can be sampled on the next falling clock edge.
--                 The next four bytes on CRC_BYTE after CALC goes low are the
--                 CRC that should be stored at the end of the frame.
--                 When reading a frame, if, after CALC goes low, the residual
--                 matches 0xdebb20e3, then VALID is asserted for one clock
--                 cycle.
--
-- Dependencies:   None
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity crc32 is
  port ( clock : in  std_logic;
         clear : in  std_logic;
         data : in  std_logic_vector (7 downto 0);
         calc : in std_logic;
         crc_byte : out std_logic_vector(7 downto 0);
         crc_reg : out std_logic_vector(31 downto 0);
         valid : out std_logic
       );
end crc32;

architecture RTL of crc32 is

  signal addr : std_logic_vector(7 downto 0);
--  signal newcrc : std_logic_vector(31 downto 0);
  signal crc : std_logic_vector(31 downto 0);
  signal final_crc : std_logic_vector(31 downto 0);
  signal finishing : std_logic;

--  attribute mark_debug : string;
--  attribute mark_debug of crc : signal is "true";

  type crc_t is array(0 to 255) of std_logic_vector(31 downto 0);
  constant crc_table : crc_t := (
X"00000000", X"77073096", X"ee0e612c", X"990951ba",
X"076dc419", X"706af48f", X"e963a535", X"9e6495a3",
X"0edb8832", X"79dcb8a4", X"e0d5e91e", X"97d2d988",
X"09b64c2b", X"7eb17cbd", X"e7b82d07", X"90bf1d91",
X"1db71064", X"6ab020f2", X"f3b97148", X"84be41de",
X"1adad47d", X"6ddde4eb", X"f4d4b551", X"83d385c7",
X"136c9856", X"646ba8c0", X"fd62f97a", X"8a65c9ec",
X"14015c4f", X"63066cd9", X"fa0f3d63", X"8d080df5",
X"3b6e20c8", X"4c69105e", X"d56041e4", X"a2677172",
X"3c03e4d1", X"4b04d447", X"d20d85fd", X"a50ab56b",
X"35b5a8fa", X"42b2986c", X"dbbbc9d6", X"acbcf940",
X"32d86ce3", X"45df5c75", X"dcd60dcf", X"abd13d59",
X"26d930ac", X"51de003a", X"c8d75180", X"bfd06116",
X"21b4f4b5", X"56b3c423", X"cfba9599", X"b8bda50f",
X"2802b89e", X"5f058808", X"c60cd9b2", X"b10be924",
X"2f6f7c87", X"58684c11", X"c1611dab", X"b6662d3d",
X"76dc4190", X"01db7106", X"98d220bc", X"efd5102a",
X"71b18589", X"06b6b51f", X"9fbfe4a5", X"e8b8d433",
X"7807c9a2", X"0f00f934", X"9609a88e", X"e10e9818",
X"7f6a0dbb", X"086d3d2d", X"91646c97", X"e6635c01",
X"6b6b51f4", X"1c6c6162", X"856530d8", X"f262004e",
X"6c0695ed", X"1b01a57b", X"8208f4c1", X"f50fc457",
X"65b0d9c6", X"12b7e950", X"8bbeb8ea", X"fcb9887c",
X"62dd1ddf", X"15da2d49", X"8cd37cf3", X"fbd44c65",
X"4db26158", X"3ab551ce", X"a3bc0074", X"d4bb30e2",
X"4adfa541", X"3dd895d7", X"a4d1c46d", X"d3d6f4fb",
X"4369e96a", X"346ed9fc", X"ad678846", X"da60b8d0",
X"44042d73", X"33031de5", X"aa0a4c5f", X"dd0d7cc9",
X"5005713c", X"270241aa", X"be0b1010", X"c90c2086",
X"5768b525", X"206f85b3", X"b966d409", X"ce61e49f",
X"5edef90e", X"29d9c998", X"b0d09822", X"c7d7a8b4",
X"59b33d17", X"2eb40d81", X"b7bd5c3b", X"c0ba6cad",
X"edb88320", X"9abfb3b6", X"03b6e20c", X"74b1d29a",
X"ead54739", X"9dd277af", X"04db2615", X"73dc1683",
X"e3630b12", X"94643b84", X"0d6d6a3e", X"7a6a5aa8",
X"e40ecf0b", X"9309ff9d", X"0a00ae27", X"7d079eb1",
X"f00f9344", X"8708a3d2", X"1e01f268", X"6906c2fe",
X"f762575d", X"806567cb", X"196c3671", X"6e6b06e7",
X"fed41b76", X"89d32be0", X"10da7a5a", X"67dd4acc",
X"f9b9df6f", X"8ebeeff9", X"17b7be43", X"60b08ed5",
X"d6d6a3e8", X"a1d1937e", X"38d8c2c4", X"4fdff252",
X"d1bb67f1", X"a6bc5767", X"3fb506dd", X"48b2364b",
X"d80d2bda", X"af0a1b4c", X"36034af6", X"41047a60",
X"df60efc3", X"a867df55", X"316e8eef", X"4669be79",
X"cb61b38c", X"bc66831a", X"256fd2a0", X"5268e236",
X"cc0c7795", X"bb0b4703", X"220216b9", X"5505262f",
X"c5ba3bbe", X"b2bd0b28", X"2bb45a92", X"5cb36a04",
X"c2d7ffa7", X"b5d0cf31", X"2cd99e8b", X"5bdeae1d",
X"9b64c2b0", X"ec63f226", X"756aa39c", X"026d930a",
X"9c0906a9", X"eb0e363f", X"72076785", X"05005713",
X"95bf4a82", X"e2b87a14", X"7bb12bae", X"0cb61b38",
X"92d28e9b", X"e5d5be0d", X"7cdcefb7", X"0bdbdf21",
X"86d3d2d4", X"f1d4e242", X"68ddb3f8", X"1fda836e",
X"81be16cd", X"f6b9265b", X"6fb077e1", X"18b74777",
X"88085ae6", X"ff0f6a70", X"66063bca", X"11010b5c",
X"8f659eff", X"f862ae69", X"616bffd3", X"166ccf45",
X"a00ae278", X"d70dd2ee", X"4e048354", X"3903b3c2",
X"a7672661", X"d06016f7", X"4969474d", X"3e6e77db",
X"aed16a4a", X"d9d65adc", X"40df0b66", X"37d83bf0",
X"a9bcae53", X"debb9ec5", X"47b2cf7f", X"30b5ffe9",
X"bdbdf21c", X"cabac28a", X"53b39330", X"24b4a3a6",
X"bad03605", X"cdd70693", X"54de5729", X"23d967bf",
X"b3667a2e", X"c4614ab8", X"5d681b02", X"2a6f2b94",
X"b40bbe37", X"c30c8ea1", X"5a05df1b", X"2d02ef8d"
  );

begin

  process ( clock, clear )
    variable crctab : std_logic_vector(31 downto 0);
    variable newcrc : std_logic_vector(31 downto 0);
  begin
    if ( clock'event and clock = '1' ) then
      if ( clear = '1' ) then
        crc <= ( others => '1' );
      else
        crctab := crc_table(to_integer(unsigned(addr)));
        if ( clear = '1' ) then
          newcrc := crctab(31 downto 24) & not crctab(23 downto 0);
        else
          newcrc := crctab xor ( x"00" & crc(31 downto 8) );
        end if;
        if ( calc = '1' ) then
          crc <= newcrc;
        else
          crc <= x"00" & crc(31 downto 8);
        end if;
      end if;
    end if;
  end process;
        
  addr <= x"00" when calc = '0' else not data when clear = '1' else
          crc(7 downto 0) xor data;
  crc_byte <= not crc(7 downto 0) when calc = '0' else x"ff";
  crc_reg <= not crc;
  valid <= '1' when calc = '0' and crc = x"debb20e3" else '0';
  
end RTL;
