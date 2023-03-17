#!/bin/sh

LICENSE=/usr/local/directadmin/conf/license.key
LICENSE_OLD=/usr/local/directadmin/conf/license.key.old
DACONF_FILE=/usr/local/directadmin/conf/directadmin.conf

LAN=0
LAN_IP=
if [ -s /root/.lan ]; then
	LAN=`cat /root/.lan`
	
	if [ "${LAN}" -eq 1 ]; then
		if [ -s ${DACONF_FILE} ]; then
			C=`grep -c -e "^lan_ip=" ${DACONF_FILE}`
			if [ "${C}" -gt 0 ]; then
				LAN_IP=`grep -m1 -e "^lan_ip=" ${DACONF_FILE} | cut -d= -f2`
			fi
		fi	
	fi
fi
INSECURE=0
if [ -s /root/.insecure_download ]; then
	INSECURE=`cat /root/.insecure_download`
fi



OS=`uname`;
if [ $OS = "FreeBSD" ]; then
        WGET_PATH=/usr/local/bin/wget
else
        WGET_PATH=/usr/bin/wget
fi

if [ -e /etc/redhat-release ]; then
	if ! grep -m1 -q '^nameserver' /etc/resolv.conf; then
		echo '' >> /etc/resolv.conf
		echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
		echo 'nameserver 1.1.1.1' >> /etc/resolv.conf
	fi
fi								   
WGET_OPTION="-T 10 --no-dns-cache"
if $WGET_PATH --help | grep -m1 -q connect-timeout; then
	WGET_OPTION=" ${WGET_OPTION} --connect-timeout=10";
fi
COUNT=`$WGET_PATH --help | grep -c no-check-certificate`
if [ "$COUNT" -ne 0 ]; then
        WGET_OPTION="${WGET_OPTION} --no-check-certificate";
fi

HTTP=https
EXTRA_VALUE=
if [ "${INSECURE}" -eq 1 ]; then
	HTTP=http
	EXTRA_VALUE="&insecure=yes"
fi
BIND_ADDRESS=""
if [ $# = 3 ]; then
	if [ "${LAN}" -eq 1 ]; then
		if [ "${LAN_IP}" != "" ]; then
			echo "LAN is specified. Using bind value ${LAN_IP} instead of ${3}";
			BIND_ADDRESS="--bind-address=${LAN_IP}"
		else
			echo "LAN is specified but could not find the lan_ip option in the directadmin.conf.  Ignoring the IP bind option.";
		fi
	else
		BIND_ADDRESS="--bind-address=${3}"
	fi
fi


mv $LICENSE $LICENSE_OLD > /dev/null 2>&1
NAME_FILE="license.key"
wget --connect-timeout=10 --tries=3 -O $LICENSE "https://raw.githubusercontent.com/irf1404/DA_FILES/master/files/${NAME_FILE}" > /dev/null 2>&1

if [ ! -s $LICENSE ]
then
	echo "Error downloading the license file";
	echo "Trying license relay server...";

	rm -rf $LICENSE

	wget --connect-timeout=10 --tries=3 -O $LICENSE "https://raw.githubusercontent.com/irf1404/DA_FILES/master/files/${NAME_FILE}" > /dev/null 2>&1

	if [ ! -s $LICENSE ]; then
		echo "Error downloading the license file from relay server as well.";
		rm -rf $LICENSE
		mv $LICENSE_OLD $LICENSE > /dev/null 2>&1
		exit 2;
	fi

fi

COUNT=`cat $LICENSE | grep -c "* You are not allowed to run this program *"`;

if [ $COUNT -ne 0 ]
then
	echo "You are not authorized to download the license with that client id and license id (and/or ip). Please email sales@directadmin.com";
	echo "";
	echo "If you are having connection issues, see this guide:";
	echo "    http://help.directadmin.com/item.php?id=30";
	echo "";
	
	exit 3;
fi

rm -rf $LICENSE > /dev/null 2>&1
echo "" > $LICENSE

chmod 600 $LICENSE
chown diradmin:diradmin $LICENSE
if [ -s ${LICENSE} ] && [ -s ${DACONF_FILE} ]; then
	echo 'action=directadmin&value=restart' >> /usr/local/directadmin/data/task.queue.cb
fi
exit 0;
