#!/bin/bash
cat << EOF  |  while read line; do echo "$line" | tee /dev/ttyUSB1; usleep 200000; done
-- setup lmk
-- setup hmc
-- setup adc0
-- setup adc1
wspi adc1 40 0
wspi adc0 40 0
wspi adc0 247 80  -- upper threshold
wspi adc1 247 80
wspi adc0 248 00
wspi adc1 248 00
wspi adc0 249 40  -- lower threshold
wspi adc1 249 40
wspi adc0 24b 20  -- dwell time
wspi adc1 24b 20
wspi adc0 245 01
wspi adc1 245 01
wspi adc0 559 00  -- FD control bits
wspi adc0 55a 03
wspi adc0 58f cb
wspi adc1 559 00
wspi adc1 55a 03
wspi adc1 58f cb
poke cf00003c 0
rate
arp 192.168.40.1
send 192.168.40.1 48879
stream 0 192.168.40.235 48879
stream 1 192.168.40.235 48879
poke c1000070 00020000
poke c8000000 10008006
poke c8000008 000003cf
EOF
