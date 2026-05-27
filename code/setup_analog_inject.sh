#!/bin/bash

cat << EOF  |  while read line; do echo "$line" | tee /dev/ttyUSB1; usleep 200000; done

conf ${1}
spy reset
spy ${1}
rdreg ${1} 2
gr ${1}

wreg ${1} 20 ffff  -- Global threshold
wreg ${1} 23 0000
wreg ${1} 24 0000

--  Clear shift register
wreg ${1} 22 300
wreg ${1} 21 0
wreg ${1} 13 8000    -- S0=0,S1=1
wreg ${1} 27 8008
gp ${1}

--  Load pixel latches
wreg ${1} 22 300
wreg ${1} 21 0
wreg ${1} 13 3ffe   -- Load all latches
wreg ${1} 27 8004   -- LEN=1
gp ${1}
wreg ${1} 13 0

--  Set shift register
wreg ${1} 22 0000
wreg ${1} 21 0001  -- PlsrDAC voltage
wreg ${1} 13 4000  -- S0=1,S1=0
wreg ${1} 27 8002
gp ${1}
wreg ${1} 13 0000

poke c80000a0 00018000
poke c80000a4 00018000
poke c80000a8 00018000
poke c80000ac 00018000
poke c80000b0 00018000
poke c80000b4 00018000
poke c80000b8 00018000
poke c80000bc 00018000
poke c80000c0 00018000
poke c80000c4 00018000
poke c80000c8 00018000
poke c80000cc 00018000
poke c80000d0 00018000
poke c80000d4 00018000
poke c80000d8 00018000
poke c80000dc 00018000
poke c80000e0 00018000
poke c80000e4 00018000
poke c80000e8 00018000
poke c80000ec 00018000
poke c80000f0 80018000

-- Load pixel latches
wreg ${1} 22 0000   -- Colpr_Addr = 0
wreg ${1} 21 00ff   -- HLD=0
wreg ${1} 13 30c0   -- Load latch bits 0,1,6,7
wfe ${1}
wreg ${1} 27 8004   -- LEN=1
gp ${1}
wreg ${1} 13 0

--  Clear shift register
wreg ${1} 22 000
wreg ${1} 21 0
wreg ${1} 13 8000    -- S0=0,S1=1
wreg ${1} 27 8008
gp ${1}

wreg ${1} 21 00ff   -- DHS=0,PlsrDAC=511
-- wreg ${1} 21 00f8   -- DHS=0,PlsrDAC=248  (almost at threshold)
wreg ${1} 2 4800    -- Trig_Count=4
wreg ${1} 26 8022   -- Delay=16, pulse width=4, HD1=1,HD0=0
wreg ${1} 27 8000   -- PLL=1,M13=0
wreg ${1} 1 0000    -- SME=0
wreg ${1} 31 f040   -- PlsrDelay=32
wreg ${1} 17 002d   -- PlsrIDACramp=180
wreg ${1} 25 b200   -- Trig_Lat
wreg ${1} 20 6001   -- Global threshold

wreg ${1} 22 0080   -- column 1

run ${1} 
--
poke c8001004 b0010066
-- poke c8000004 80660201
--
spy fifo

EOF
