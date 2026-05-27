#!/bin/bash
ir=0
for ic in {0..79}
do
  for ir in {280..289}
  do
    echo Trimming column $ic row $ir...
    time ./fei4_trim 192.168.40.236 0 ${ic} ${ir} 4 channel_0.root
  done
done
