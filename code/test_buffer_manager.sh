#!/bin/bash
cat << EOF  |  while read line; do echo "$line" | tee /dev/ttyUSB1; usleep 200000; done
poke c8000008 000003cf
-- poke c8000000 08008000
poke c8000000 00008000
link clr
run 0
run 2
run 6
run 8
-- ecr 0
-- ecr 2
-- ecr 6
-- ecr 8
spy 9
spy reset
poke c8000004 80660101
link
EOF
