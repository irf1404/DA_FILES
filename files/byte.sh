#!/bin/sh

FILE=/usr/local/directadmin/directadmin
DEC=`echo $(( 16#$2 ))`
echo $DEC
service directadmin stop
printf "\x$1" | dd of="$FILE" bs=1 seek=$DEC count=1 conv=notrunc
service directadmin restart
