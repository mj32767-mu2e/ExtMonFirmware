#!/bin/bash
cat << EOF  |  while read line; do echo "$line" | tee /dev/ttyUSB1; usleep 200000; done
setup lmk
setup hmc
setup adc0
setup adc1
wspi adc1 40 0
wspi adc0 40 0
wspi adc0 247 80
wspi adc1 247 80
wspi adc0 248 00
wspi adc1 248 00
wspi adc0 249 40
wspi adc1 249 40
wspi adc0 24b 40
wspi adc1 24b 40
wspi adc0 245 1
wspi adc1 245 1
poke cf00003c 0
rate
setup ad9517
setup ads42lb69
wspi adc2 f 0
arp 192.168.40.1
send 192.168.40.1 48879
stream 192.168.40.1 48879
poke c600001c f9da
poke c6000018 100
poke c600003c 1
poke c1000070 20000
poke c6000018 05000500
poke c6000044 c0
poke c600003c 0
poke c6000060 ff
peek c6000060
EOF
