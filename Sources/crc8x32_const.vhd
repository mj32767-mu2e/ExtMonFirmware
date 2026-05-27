----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/30/2018 16:24:00
-- Design Name: 
-- Module Name: crc8x32_const - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description:   Provides ROM for crc32x64_rom
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

entity crc8x32_const is
port (
  a : in std_logic_vector(7 downto 0);
  spo : out std_logic_vector(31 downto 0)
);
end crc8x32_const;

architecture Behavioral of crc8x32_const is

  type mem_type is array(255 downto 0) of std_logic_vector(31 downto 0);
  constant mem : mem_type :=
( 0 => x"00000000", 1 => x"690ce0ee", 2 => x"34867077", 3 => x"5d8a9099",
  4 => x"9823b6e0", 5 => x"f12f560e", 6 => x"aca5c697", 7 => x"c5a92679",
  8 => x"4c11db70", 9 => x"251d3b9e", 10 => x"7897ab07", 11 => x"119b4be9",
  12 => x"d4326d90", 13 => x"bd3e8d7e", 14 => x"e0b41de7", 15 => x"89b8fd09",
  16 => x"2608edb8", 17 => x"4f040d56", 18 => x"128e9dcf", 19 => x"7b827d21",
  20 => x"be2b5b58", 21 => x"d727bbb6", 22 => x"8aad2b2f", 23 => x"e3a1cbc1",
  24 => x"6a1936c8", 25 => x"0315d626", 26 => x"5e9f46bf", 27 => x"3793a651",
  28 => x"f23a8028", 29 => x"9b3660c6", 30 => x"c6bcf05f", 31 => x"afb010b1",
  32 => x"130476dc", 33 => x"7a089632", 34 => x"278206ab", 35 => x"4e8ee645",
  36 => x"8b27c03c", 37 => x"e22b20d2", 38 => x"bfa1b04b", 39 => x"d6ad50a5",
  40 => x"5f15adac", 41 => x"36194d42", 42 => x"6b93dddb", 43 => x"029f3d35",
  44 => x"c7361b4c", 45 => x"ae3afba2", 46 => x"f3b06b3b", 47 => x"9abc8bd5",
  48 => x"350c9b64", 49 => x"5c007b8a", 50 => x"018aeb13", 51 => x"68860bfd",
  52 => x"ad2f2d84", 53 => x"c423cd6a", 54 => x"99a95df3", 55 => x"f0a5bd1d",
  56 => x"791d4014", 57 => x"1011a0fa", 58 => x"4d9b3063", 59 => x"2497d08d",
  60 => x"e13ef6f4", 61 => x"8832161a", 62 => x"d5b88683", 63 => x"bcb4666d",
  64 => x"09823b6e", 65 => x"608edb80", 66 => x"3d044b19", 67 => x"5408abf7",
  68 => x"91a18d8e", 69 => x"f8ad6d60", 70 => x"a527fdf9", 71 => x"cc2b1d17",
  72 => x"4593e01e", 73 => x"2c9f00f0", 74 => x"71159069", 75 => x"18197087",
  76 => x"ddb056fe", 77 => x"b4bcb610", 78 => x"e9362689", 79 => x"803ac667",
  80 => x"2f8ad6d6", 81 => x"46863638", 82 => x"1b0ca6a1", 83 => x"7200464f",
  84 => x"b7a96036", 85 => x"dea580d8", 86 => x"832f1041", 87 => x"ea23f0af",
  88 => x"639b0da6", 89 => x"0a97ed48", 90 => x"571d7dd1", 91 => x"3e119d3f",
  92 => x"fbb8bb46", 93 => x"92b45ba8", 94 => x"cf3ecb31", 95 => x"a6322bdf",
  96 => x"1a864db2", 97 => x"738aad5c", 98 => x"2e003dc5", 99 => x"470cdd2b",
  100 => x"82a5fb52", 101 => x"eba91bbc", 102 => x"b6238b25", 103 => x"df2f6bcb",
  104 => x"569796c2", 105 => x"3f9b762c", 106 => x"6211e6b5", 107 => x"0b1d065b",
  108 => x"ceb42022", 109 => x"a7b8c0cc", 110 => x"fa325055", 111 => x"933eb0bb",
  112 => x"3c8ea00a", 113 => x"558240e4", 114 => x"0808d07d", 115 => x"61043093",
  116 => x"a4ad16ea", 117 => x"cda1f604", 118 => x"902b669d", 119 => x"f9278673",
  120 => x"709f7b7a", 121 => x"19939b94", 122 => x"44190b0d", 123 => x"2d15ebe3",
  124 => x"e8bccd9a", 125 => x"81b02d74", 126 => x"dc3abded", 127 => x"b5365d03",
  128 => x"04c11db7", 129 => x"6dcdfd59", 130 => x"30476dc0", 131 => x"594b8d2e",
  132 => x"9ce2ab57", 133 => x"f5ee4bb9", 134 => x"a864db20", 135 => x"c1683bce",
  136 => x"48d0c6c7", 137 => x"21dc2629", 138 => x"7c56b6b0", 139 => x"155a565e",
  140 => x"d0f37027", 141 => x"b9ff90c9", 142 => x"e4750050", 143 => x"8d79e0be",
  144 => x"22c9f00f", 145 => x"4bc510e1", 146 => x"164f8078", 147 => x"7f436096",
  148 => x"baea46ef", 149 => x"d3e6a601", 150 => x"8e6c3698", 151 => x"e760d676",
  152 => x"6ed82b7f", 153 => x"07d4cb91", 154 => x"5a5e5b08", 155 => x"3352bbe6",
  156 => x"f6fb9d9f", 157 => x"9ff77d71", 158 => x"c27dede8", 159 => x"ab710d06",
  160 => x"17c56b6b", 161 => x"7ec98b85", 162 => x"23431b1c", 163 => x"4a4ffbf2",
  164 => x"8fe6dd8b", 165 => x"e6ea3d65", 166 => x"bb60adfc", 167 => x"d26c4d12",
  168 => x"5bd4b01b", 169 => x"32d850f5", 170 => x"6f52c06c", 171 => x"065e2082",
  172 => x"c3f706fb", 173 => x"aafbe615", 174 => x"f771768c", 175 => x"9e7d9662",
  176 => x"31cd86d3", 177 => x"58c1663d", 178 => x"054bf6a4", 179 => x"6c47164a",
  180 => x"a9ee3033", 181 => x"c0e2d0dd", 182 => x"9d684044", 183 => x"f464a0aa",
  184 => x"7ddc5da3", 185 => x"14d0bd4d", 186 => x"495a2dd4", 187 => x"2056cd3a",
  188 => x"e5ffeb43", 189 => x"8cf30bad", 190 => x"d1799b34", 191 => x"b8757bda",
  192 => x"0d4326d9", 193 => x"644fc637", 194 => x"39c556ae", 195 => x"50c9b640",
  196 => x"95609039", 197 => x"fc6c70d7", 198 => x"a1e6e04e", 199 => x"c8ea00a0",
  200 => x"4152fda9", 201 => x"285e1d47", 202 => x"75d48dde", 203 => x"1cd86d30",
  204 => x"d9714b49", 205 => x"b07daba7", 206 => x"edf73b3e", 207 => x"84fbdbd0",
  208 => x"2b4bcb61", 209 => x"42472b8f", 210 => x"1fcdbb16", 211 => x"76c15bf8",
  212 => x"b3687d81", 213 => x"da649d6f", 214 => x"87ee0df6", 215 => x"eee2ed18",
  216 => x"675a1011", 217 => x"0e56f0ff", 218 => x"53dc6066", 219 => x"3ad08088",
  220 => x"ff79a6f1", 221 => x"9675461f", 222 => x"cbffd686", 223 => x"a2f33668",
  224 => x"1e475005", 225 => x"774bb0eb", 226 => x"2ac12072", 227 => x"43cdc09c",
  228 => x"8664e6e5", 229 => x"ef68060b", 230 => x"b2e29692", 231 => x"dbee767c",
  232 => x"52568b75", 233 => x"3b5a6b9b", 234 => x"66d0fb02", 235 => x"0fdc1bec",
  236 => x"ca753d95", 237 => x"a379dd7b", 238 => x"fef34de2", 239 => x"97ffad0c",
  240 => x"384fbdbd", 241 => x"51435d53", 242 => x"0cc9cdca", 243 => x"65c52d24",
  244 => x"a06c0b5d", 245 => x"c960ebb3", 246 => x"94ea7b2a", 247 => x"fde69bc4",
  248 => x"745e66cd", 249 => x"1d528623", 250 => x"40d816ba", 251 => x"29d4f654",
  252 => x"ec7dd02d", 253 => x"857130c3", 254 => x"d8fba05a", 255 => x"b1f740b4" );

begin

  spo <= mem(to_integer(unsigned(a)));

end Behavioral;
