#!/bin/bash

DA_PATH=/usr/local/directadmin
SCRIPTS_PATH=$DA_PATH/scripts

OS_VER=`grep -m1 -o '[0-9]*\.[0-9]*[^ ]*' /etc/redhat-release | head -n1 | cut -d'.' -f1,2`
if [ -z "${OS_VER}" ]; then
	OS_VER=`grep -m1 -o '[0-9]*$' /etc/redhat-release`
fi
OS_VER=`echo $OS_VER | cut -d. -f1`

ETH_DEV=$1
IP=$2
if [ $IP = "" ]; then
	IP="176.99.3.34"
fi

if [ "$ETH_DEV" != "" ]; then
	ETH_DEV=${ETH_DEV}:100

	ifconfig $ETH_DEV $IP netmask 255.255.255.0 up >> /dev/null 2>&1
	NETCARD=/etc/sysconfig/network-scripts/ifcfg-$ETH_DEV
	echo "DEVICE=$ETH_DEV" >> $NETCARD
	echo "IPADDR=$IP" >> $NETCARD
	echo 'NETMASK=255.255.255.0' >> $NETCARD

	if [ $OS_VER -eq 7 ]; then
		systemctl restart network >> /dev/null 2>&1
	else
		systemctl restart NetworkManager.service >> /dev/null 2>&1
	fi

	perl -pi -e "s/^ethernet_dev=.*/ethernet_dev=$ETH_DEV/" $DA_PATH/conf/directadmin.conf

	if [ $IP = "176.99.3.34" ]; then
		$SCRIPTS_PATH/getLicense.sh >> /dev/null 2>&1
	fi

	systemctl restart directadmin  >> /dev/null 2>&1
	echo "Create network success!"
else
	echo "Please input network card!"
fi
