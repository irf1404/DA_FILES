#!/bin/bash

DA_PATH=/usr/local/directadmin
SCRIPTS_PATH=$DA_PATH/scripts

OS_VER=`grep -m1 -o '[0-9]*\.[0-9]*[^ ]*' /etc/redhat-release | head -n1 | cut -d'.' -f1,2`
if [ -z "${OS_VER}" ]; then
	OS_VER=`grep -m1 -o '[0-9]*$' /etc/redhat-release`
fi
OS_VER=`echo $OS_VER | cut -d. -f1`

NETCARD=`echo \`ip a | grep "inet .* brd .* scope global .* "\` > card && cat card && rm -rf card`
echo ""
echo "Your IP and network card: $NETCARD"
echo ""

yesno="n"
while [ "$yesno" = "n" ]; do
{
	echo -n "Input your network card name to run directadmin: ";
	read ETH_DEV;

	if [ "$ETH_DEV" = "" ] || [ -z "`echo $NETCARD | grep \"$ETH_DEV\"`" ]; then
		echo "Invalid network card name!"
		echo ""
	else
		yesno="y"
	fi
}
done;

IP="176.99.3.34"

yesno="n"
while [ "$yesno" = "n" ]; do
{
	echo -n "Do you want to run directadmin with IP=$IP or other IP? (y,n): ";
	read yesno;

	while [ "$yesno" = "n" ]; do
	{
		echo -n "Please input your IP to run directadmin: ";
		read IP;

		if [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			yesno="y";
		else
			echo "The $IP you entered is not valid!";
			echo ""
		fi
	}
	done;
}
done;

echo ""
echo "Network Card Name: $ETH_DEV"
echo "IP: $IP"

if [ "$ETH_DEV" != "" ]; then
	ETH_DEV=${ETH_DEV}:100
	NETCARD=/etc/sysconfig/network-scripts/ifcfg-$ETH_DEV
	ifconfig $ETH_DEV $IP netmask 255.255.255.0 up >> /dev/null 2>&1
	echo "DEVICE=$ETH_DEV" > $NETCARD
	echo "IPADDR=$IP" >> $NETCARD
	echo 'NETMASK=255.255.255.0' >> $NETCARD
	echo 'ONBOOT=yes' >> $NETCARD

	# Add autoboot network card
	echo `crontab -l > file_cron_network` >> /dev/null 2>&1
	sed -i '/@reboot.*directadmin/d' file_cron_network
	echo "@reboot sleep 30 && sudo ifconfig $ETH_DEV $IP netmask 255.255.255.0 up && sudo systemctl restart directadmin" >> file_cron_network
	crontab file_cron_network
	rm -rf file_cron_network
	
	perl -pi -e "s/^ethernet_dev=.*/ethernet_dev=$ETH_DEV/" $DA_PATH/conf/directadmin.conf

	if [ "$IP" = "176.99.3.34" ]; then
		$SCRIPTS_PATH/getLicense.sh >> /dev/null 2>&1
	fi

	echo ""
	echo "Create network success!"

	systemctl restart directadmin  >> /dev/null 2>&1
	if [ $? -gt 0 ]; then
		echo "Directadmin not working!"
		echo "Please try config network card again!"
		echo "https://github.com/irf1404/DA_FILES"
	fi

	printf \\a
	sleep 1
	printf \\a
	sleep 1
	printf \\a
fi