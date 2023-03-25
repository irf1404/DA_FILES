#!/bin/bash

service directadmin stop
if [ ! $1 ]; then
  if [ ! -s /root/byte ]; then
    echo "0" > /root/byte
  fi
  DEC=`cat /root/byte`
else
  DEC=$1
fi
DEC_TO_HEX=`printf "%x\n" $DEC`
typeset -i DEC_INT=$DEC
if [ $DEC_INT -lt 16 ]; then
  DEC_TO_HEX="0${DEC_TO_HEX}"
fi
typeset -i DEC_INT_M=$DEC_INT+1
echo $DEC_INT_M > /root/byte
printf "\x${DEC_TO_HEX}" | dd of=/usr/local/directadmin/directadmin bs=1 seek=475419 count=1 conv=notrunc
service directadmin start
echo "$DEC  $DEC_TO_HEX"
