#!/bin/bash

cat << EOF  |  while read line; do echo "$line" | tee /dev/ttyUSB0; usleep 200000; done

conf 0
spy reset
rdreg 0 2
gr 0

wreg 0 20 ffff  -- Global threshold
wreg 0 23 0000
wreg 0 24 0000

--  Clear shift register
wreg 0 22 300
wreg 0 21 0
wreg 0 13 8000    -- S0=0,S1=1
wreg 0 27 8008
gp 0

--  Load pixel latches
wreg 0 22 300
wreg 0 21 0
wreg 0 13 3ffe   -- Load all latches
wreg 0 27 8004   -- LEN=1
gp 0
wreg 0 13 0

--  Set shift register
wreg 0 22 0000
wreg 0 21 0001  -- PlsrDAC voltage
wreg 0 13 4000  -- S0=1,S1=0
wreg 0 27 8002
gp 0
wreg 0 13 0000

poke c80000a0 00000000
poke c80000a4 00000000
poke c80000a8 00000000
poke c80000ac 00000000
poke c80000b0 00000000
poke c80000b4 00000000
poke c80000b8 00000000
poke c80000bc 00000000
poke c80000c0 00000000
poke c80000c4 00000000
poke c80000c8 00018000
poke c80000cc 00000000
poke c80000d0 00000000
poke c80000d4 00000000
poke c80000d8 00000000
poke c80000dc 00000000
poke c80000e0 00000000
poke c80000e4 00000000
poke c80000e8 00000000
poke c80000ec 00000000
poke c80000f0 80000000

-- Load pixel latches
wreg 0 22 0000   -- Colpr_Addr = 0
wreg 0 21 00ff   -- HLD=0
wreg 0 13 30c0   -- Load latch bits 0,1,6,7
wfe 0
wreg 0 27 8004   -- LEN=1
gp 0
wreg 0 13 0

--  Clear shift register
wreg 0 22 000
wreg 0 21 0
wreg 0 13 8000    -- S0=0,S1=1
wreg 0 27 8008
gp 0

wreg 0 21 00ff   -- DHS=0,PlsrDAC=511
-- wreg 0 21 00f8   -- DHS=0,PlsrDAC=248  (almost at threshold)
wreg 0 2 4800    -- Trig_Count=4
wreg 0 26 8022   -- Delay=16, pulse width=4, HD1=1,HD0=0
wreg 0 27 8000   -- PLL=1,M13=0
wreg 0 1 0000    -- SME=0
wreg 0 31 f040   -- PlsrDelay=32
wreg 0 17 002d   -- PlsrIDACramp=180
wreg 0 25 b200   -- Trig_Lat
wreg 0 20 0001   -- Global threshold

wreg 0 22 0080   -- column 1

run 0
--
poke c8001004 b0010066
-- poke c8000004 80660201
--
spy fifo

EOF
