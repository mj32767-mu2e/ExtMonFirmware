#!/bin/bash
cat << EOF  |  while read line; do echo "$line" | tee /dev/ttyUSB5; usleep 200000; done
stream 0 192.168.40.1 48879 on
send 192.168.40.1 48879
poke cf000060 ff
poke cf000070 80000000
wspi adc0 40 0
wspi adc0 247 80
wspi adc0 248 0
wspi adc0 249 40
wspi adc0 24b 40
wspi adc0 245 1

wspi adc1 40 0
wspi adc1 247 80
wspi adc1 248 0
wspi adc1 249 40
wspi adc1 24b 40
wspi adc1 245 1

rate
poke cf00003c 0
poke cf000060 ff
poke ce000000 40000000   -- enable PCIe interrupts
EOF
