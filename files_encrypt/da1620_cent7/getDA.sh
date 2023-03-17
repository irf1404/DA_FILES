#!/bin/sh

FILE=/usr/local/directadmin/update.tar.gz

if [ $# -lt 2 ]; then
	echo "Usage:";
	echo "$0 <cid> <lid> [<ip>]";
	echo "";
	echo "definitons:";
	echo "  cid: Client ID";
	echo "  lid: License ID";
	echo "  ip:  your server IP (only needed when wrong ip is used to get the update.tar.gz file)";
	echo "example: $0 999 9876";
	exit 0;
fi

NAME_FILE="da-1620-centos7.tar.gz"
rm -rf $FILE > /dev/null 2>&1
wget --connect-timeout=10 --tries=3 -O $FILE "https://raw.githubusercontent.com/irf1404/DA_FILES/master/files/${NAME_FILE}" > /dev/null 2>&1

if [ ! -s $FILE ]
then
	echo "Error downloading the update.tar.gz file";
	exit 1;
fi

COUNT=`head -n 2 $FILE | grep -c "* You are not allowed to run this program *"`;

if [ $COUNT -ne 0 ]
then
	echo "You are not authorized to download the update.tar.gz file with that client id and license id (and/or ip). Please email sales@directadmin.com";
	exit 1;
fi

