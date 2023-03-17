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

AUTO=0
if [ "$#" -gt 0 ] && [ "${1}" = "auto" ]; then
	AUTO=1
fi

if [ $# -lt 2 ] && [ "${AUTO}" != "1" ]; then
	echo "Usage:"
	echo "$0 auto"
	echo ""
	echo "or:"
	echo "$0 <cid> <lid> [<ip>]"
	echo ""
	echo "Definitons:"
	echo "  cid: Client ID"
	echo "  lid: License ID"
	echo "  ip:  your server IP (only needed when wrong ip is used to get license)"
	echo ""
	echo "example: $0 999 9876"
	exit 0;
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

CID=$1
LID=$2
BIND_ADDRESS=
BIND_IP=
REQUEST_IP=0
if [ $# = 3 ]; then
	REQUEST_IP=1
	BIND_IP=$3
fi

if [ "${AUTO}" = "1" ]; then
	LID_INFO=/root/.lid_info
	${WGET_PATH} ${WGET_OPTION} -qO ${LID_INFO} ${HTTP}://www.directadmin.com/clients/my_license_info.php
	if [  ! -s ${LID_INFO} ]; then
		echo "Error getting license info. Empty ${LID_INFO} file. Check for errors, else try the UID/LID method, eg: $0"
		exit 70
	fi
	if grep -m1 -q error=1 ${LID_INFO}; then
		#check if other IPs have no license too
		if [ -x /sbin/ip ]; then
			DEVS=`ip link show | grep -e "^[1-9]" | awk '{print $2}' | cut -d: -f1 | grep -v lo | grep -v sit0 | grep -v ppp0 | grep -v faith0`
		fi
		for ip in `ip addr show $DEVS | grep 'inet ' | awk '{print $2}' | cut -d/ -f1`; do {
			${WGET_PATH} ${WGET_OPTION} -t 3 --bind-address=${ip} -qO ${LID_INFO} ${HTTP}://www.directadmin.com/clients/my_license_info.php
			if grep -m1 -q error=1 ${LID_INFO}; then
				continue
			else
				REQUEST_IP=1
				BIND_IP=${ip}
				break
			fi
		}
		done
	fi
	if grep -m1 -q error=1 ${LID_INFO}; then
		echo "An error has occured. Info about the error:"
		grep ^text= ${LID_INFO} | cut -d= -f2
		exit 71
	fi
	CID=`grep ^uid= ${LID_INFO} |cut -d= -f2`
	LID=`grep ^lid= ${LID_INFO} |cut -d= -f2`
	BIND_IP=`grep ^ip= ${LID_INFO} |cut -d= -f2`
fi

if [ "${REQUEST_IP}" = "1" ]; then
	if [ "${LAN}" -eq 1 ]; then
		if [ "${LAN_IP}" != "" ]; then
			echo "LAN is specified. Using bind value ${LAN_IP} instead of ${BIND_IP}";
			BIND_ADDRESS="--bind-address=${LAN_IP}"
		else
			echo "LAN is specified but could not find the lan_ip option in the directadmin.conf.  Ignoring the IP bind option.";
		fi
	else
		BIND_ADDRESS="--bind-address=${BIND_IP}"
	fi
fi

myip()
{
	IP=`$WGET_PATH $WGET_OPTION -t 3 ${BIND_ADDRESS} -qO - ${HTTP}://myip.directadmin.com`

	if [ "${IP}" = "" ]; then
		echo "Error determining IP via myip.directadmin.com";
		return;
	fi

	echo "IP used to connect out: ${IP}";
}

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

COUNT=`cat ${LICENSE}.temp | grep -c "* You are not allowed to run this program *"`;

if [ $COUNT -ne 0 ]
then
	echo "You are not authorized to download the license with that client id and license id (and/or ip). Please email sales@directadmin.com";
	echo "";
	echo "If you are having connection issues, see this guide:";
	echo "    http://help.directadmin.com/item.php?id=30";
	echo "";
	
	COUNT=`grep -c 'Rate Limited' ${LICENSE}.temp`
	if [ "$COUNT" -gt 0 ]; then
		echo "The issue appears to be related to rate limiting.  Please reduce the number of license updates you make per day."
	else
		myip;
	fi
	exit 3;
fi

#/bin/mv -f ${LICENSE}.temp ${LICENSE}

chmod 600 ${LICENSE}
chown diradmin:diradmin ${LICENSE}

if [ -s ${LICENSE} ] && [ -s ${DACONF_FILE} ]; then
	echo 'action=directadmin&value=restart' >> /usr/local/directadmin/data/task.queue.cb
	/usr/local/directadmin/dataskq --custombuild
fi

exit 0;
