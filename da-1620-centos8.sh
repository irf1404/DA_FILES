#!/bin/sh

if [ "$(id -u)" != "0" ]; then
	echo "Please run as root!"
	exit 1
fi

Help()
{
	echo " ###########################################################################"
	echo " # ./setup.sh \$1 \$2 \$3 \$4 \$5                                               #"
	echo " # \$1: Mode (auto | normal)                                                #"
	echo " # \$2: Host (Default server.test.com)                                      #"
	echo " # \$3: AdminPass                                                           #"
	echo " # \$4: IP Server                                                           #"
	echo " # \$5: Network Card                                                        #"
	echo " # Ex: ./setup.sh auto server.nguyentrunghau.me admin@123 1.2.3.4 eth0:100 #"
	echo " # Ex: ./setup.sh auto server.nguyentrunghau.me rand                       #"
	echo " # Ex: ./setup.sh normal server.nguyentrunghau.me                          #"
	echo " ###########################################################################"
}

while getopts ":h" option; do
   case $option in
      h) Help
         exit;;
   esac
done

OS_VER=`grep -m1 -o '[0-9]*\.[0-9]*[^ ]*' /etc/redhat-release | head -n1 | cut -d'.' -f1,2`
if [ -z "${OS_VER}" ]; then
	OS_VER=`grep -m1 -o '[0-9]*$' /etc/redhat-release`
fi
OS_VER=`echo $OS_VER | cut -d. -f1`
B64=`uname -m | grep -c 64`
NAME_FILE=`grep "da.*\.sh" tmp | cut -d'/' -f7 | cut -d'.' -f1`

if [ $OS_VER -eq 7 ]; then
	yum -y install iptables wget tar gcc gcc-c++ flex bison make bind bind-libs bind-utils openssl openssl-devel perl quota libaio \
		libcom_err-devel libcurl-devel gd zlib-devel zip unzip libcap-devel cronie bzip2 cyrus-sasl-devel perl-ExtUtils-Embed \
		autoconf automake libtool which patch mailx bzip2-devel lsof glibc-headers kernel-devel expat-devel \
		psmisc net-tools systemd-devel libdb-devel perl-DBI perl-Perl4-CoreLibs perl-libwww-perl xfsprogs rsyslog logrotate crontabs file kernel-headers ipset nano
else
	yum -y install iptables wget tar gcc gcc-c++ flex bison make bind bind-libs bind-utils openssl openssl-devel perl quota libaio \
		libcom_err-devel libcurl-devel gd zlib-devel zip unzip libcap-devel cronie bzip2 cyrus-sasl-devel perl-ExtUtils-Embed \
		autoconf automake libtool which patch mailx bzip2-devel lsof glibc-headers kernel-devel expat-devel \
		psmisc net-tools systemd-devel libdb-devel perl-DBI perl-libwww-perl xfsprogs rsyslog logrotate crontabs file \
		kernel-headers hostname ipset nano network-scripts
fi


if [ ! -e /usr/bin/perl ] || [ ! -e /usr/bin/wget ]; then
	echo "Not found perl or wget! Please run:";
	echo "yum -y install wget perl";
	exit 1;
fi

if [ ! $B64 -eq 1 ]; then
	echo "Error! Script can only run on centOS x64!"
	echo "Please reinstall to centOS x64 then run again!"
	exit 1
fi

random_pass()
{
	PASS_LEN=`perl -le 'print int(rand(6))+9'`
	START_LEN=`perl -le 'print int(rand(8))+1'`
	END_LEN=$(expr ${PASS_LEN} - ${START_LEN})
	SPECIAL_CHAR=`perl -le 'print map { (qw{@ ^ _ - /})[rand 6] } 1'`;
	NUMERIC_CHAR=`perl -le 'print int(rand(10))'`;
	PASS_START=`perl -le "print map+(A..Z,a..z,0..9)[rand 62],0..$START_LEN"`;
	PASS_END=`perl -le "print map+(A..Z,a..z,0..9)[rand 62],0..$END_LEN"`;
	PASS=${PASS_START}${SPECIAL_CHAR}${NUMERIC_CHAR}${PASS_END}
	echo $PASS
}

ADMIN_USER=admin
DB_USER=da_admin
ADMIN_PASS=$3
if [ "$ADMIN_PASS" = "rand" ] || [ "$ADMIN_PASS" = "" ]; then
	ADMIN_PASS=`random_pass`
fi

DB_ROOT_PASS=`random_pass`
CMD_LINE=0

DA_PATH=/usr/local/directadmin
CB_OPTIONS=${DA_PATH}/custombuild/options.conf
SCRIPTS_PATH=$DA_PATH/scripts
PACKAGES=$SCRIPTS_PATH/packages
SETUP=$SCRIPTS_PATH/setup.txt
SERVER_SERVICES=https://raw.githubusercontent.com/irf1404/DA_REPO/master/services
SERVER_FILES=https://raw.githubusercontent.com/irf1404/DA_FILES/master
CBPATH=$DA_PATH/custombuild
BUILD=$CBPATH/build

HOST=$2
if [ "$HOST" = "" ]; then
	HOST="server.test.com"
fi

EMAIL=${ADMIN_USER}@${HOST}
TEST=`echo $HOST | cut -d. -f3`
if [ "$TEST" = "" ]
then
        NS1=ns1.`echo $HOST | cut -d. -f1,2`
        NS2=ns2.`echo $HOST | cut -d. -f1,2`
else
        NS1=ns1.`echo $HOST | cut -d. -f2,3,4,5,6`
        NS2=ns2.`echo $HOST | cut -d. -f2,3,4,5,6`
fi

ETH_DEV=$5
if [ "$ETH_DEV" = "" ]; then
	ETH_DEV=hca
fi

NM=255.255.255.0

IP=$4
if [ "$IP" = "" ]; then
	IP=`wget -q -O - http://myip.directadmin.com`
fi

PWD_DIR=`pwd`
mkdir -p $CBPATH
mkdir -p $PACKAGES
wget -O ${SCRIPTS_PATH}/command.sh $SERVER_FILES/command.sh > /dev/null 2>&1
chmod 755 ${SCRIPTS_PATH}/command.sh
${SCRIPTS_PATH}/command.sh
cd ${PWD_DIR}

if [ -s $CB_OPTIONS ]; then
	if [ `grep -c '^php1_release=' ${CB_OPTIONS}` -gt 1 ]; then
		echo "Options.conf is exist! Removing options.conf..."
		rm -f $CB_OPTIONS
	fi
fi

chmod 755 $BUILD

if [ "$1" != "auto" ]; then
	$BUILD create_options
else
	wget -O $CB_OPTIONS $SERVER_SERVICES/custombuild/options.conf
	wget -O $CBPATH/php_extensions.conf $SERVER_SERVICES/custombuild/php_extensions.conf
fi

if [ $OS_VER -eq 7 ]; then
	FILES_PATH=es_7.0_64
	SERVICES=services_es70_64.tar.gz
else
	FILES_PATH=es_8.0_64
	SERVICES=services_es80_64.tar.gz
fi

checkFile()
{
	if [ -e $1 ]; then
		echo 1;
	else
		echo 0;
	fi
}

WEBALIZER=`checkFile /usr/bin/webalizer`;
BIND=`checkFile /usr/sbin/named`;
PATCH=`checkFile /usr/bin/patch`;
SSL_H=/usr/include/openssl/ssl.h
SSL_DEVEL=`checkFile ${SSL_H}`;

addPackage()
{
	if [ "$2" = "" ]; then
		return;
	fi
	
	wget -O $PACKAGES/$2 $SERVER_SERVICES/$FILES_PATH/$2
	if [ ! -e $PACKAGES/$2 ]; then
		echo "Error downloading $SERVER_SERVICES/$FILES_PATH/$2";
	fi
	
	rpm -Uvh --nodeps --force $PACKAGES/$2
}

if [ ! -e /usr/bin/perl ]; then
	ln -s /usr/local/bin/perl /usr/bin/perl
fi

if [ ! -e /etc/ld.so.conf ] || [ "`grep -c -E '/usr/local/lib$' /etc/ld.so.conf`" = "0" ]; then
        echo "/usr/local/lib" >> /etc/ld.so.conf
        ldconfig
fi

if [ $WEBALIZER -eq 0 ]; then
	WEBALIZER_FILE=/usr/bin/webalizer
	wget -O $WEBALIZER_FILE $SERVER_SERVICES/$FILES_PATH/webalizer
	chmod 755 $WEBALIZER_FILE
fi

if [ ! -s /etc/systemd/system/named.service ]; then
	if [ -s /usr/lib/systemd/system/named.service ]; then
		mv /usr/lib/systemd/system/named.service /etc/systemd/system/named.service
	else
		wget -O /etc/systemd/system/named.service ${SERVER_SERVICES}/named/named.service
	fi
fi
if [ ! -s /usr/lib/systemd/system/named-setup-rndc.service ]; then
	wget -O /usr/lib/systemd/system/named-setup-rndc.service ${SERVER_SERVICES}/named/named-setup-rndc.service
fi

systemctl daemon-reload
systemctl enable named.service

RNDCKEY=/etc/rndc.key

if [ ! -s $RNDCKEY ]; then
	echo "Generating new key: $RNDCKEY ...";
	
	if [ -e /dev/urandom ]; then
		/usr/sbin/rndc-confgen -a -r /dev/urandom
	else
		/usr/sbin/rndc-confgen -a
	fi

	COUNT=`grep -c 'key "rndc-key"' $RNDCKEY`
	if [ "$COUNT" -eq 1 ]; then
		perl -pi -e 's/key "rndc-key"/key "rndckey"/' $RNDCKEY
	fi
	
	echo "Done generating new key";
fi

if [ ! -s $RNDCKEY ]; then
	echo "rndc-confgen failed. Using template instead.";
	
	wget -O $RNDCKEY http://www.directadmin.com/rndc.key
	if [ `cat $RNDCKEY | grep -c secret` -eq 0 ]; then
		SECRET=`/usr/sbin/rndc-confgen | grep secret | head -n 1`
		STR="perl -pi -e 's#hmac-md5;#hmac-md5;\n\t$SECRET#' $RNDCKEY;"
		eval $STR;
	fi
	
	echo "Template installed.";
fi

chown named:named ${RNDCKEY}

if [ -e /etc/sysconfig/named ]; then
        /usr/bin/perl -pi -e 's/^ROOTDIR=.*/ROOTDIR=/' /etc/sysconfig/named
fi

if [ $SSL_DEVEL -eq 0 ]; then
	echo "Not found ${SSL_H}! Please run: ";
	echo "yum -y install openssl openssl-devel";
	exit 1;
fi

groupadd apache >/dev/null 2>&1
if [ "$OS" = "debian" ]; then
	useradd -d /var/www -g apache -s /bin/false apache >/dev/null 2>&1
else
	useradd -d /var/www -g apache -r -s /bin/false apache >/dev/null 2>&1
fi
mkdir -p /etc/httpd/conf >/dev/null 2>&1

if [ -e /etc/selinux/config ]; then
	perl -pi -e 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
	perl -pi -e 's/SELINUX=permissive/SELINUX=disabled/' /etc/selinux/config
fi

if [ -e /selinux/enforce ]; then
	echo "0" > /selinux/enforce
fi

if [ -e /usr/sbin/setenforce ]; then
        /usr/sbin/setenforce 0
fi

if [ -s /usr/sbin/ntpdate ]; then
	/usr/sbin/ntpdate -b -u ntp.directadmin.com
else
	if [ -s /usr/bin/rdate ]; then
		/usr/bin/rdate -s rdate.directadmin.com
	fi
fi

DATE_BIN=/bin/date
if [ -x $DATE_BIN ]; then
	NOW=`$DATE_BIN +%s`
	if [ "$NOW" -eq "$NOW" ] 2>/dev/null; then
		if [ "$NOW" -lt 1470093542 ]; then
			echo "Your system date is not correct ($NOW). Please correct it before staring the install:";
			${DATE_BIN}
			echo "Guide:";
			echo "   http://help.directadmin.com/item.php?id=52";
			exit 1;
		fi
	else
		echo "'$NOW' is not a valid integer. Check the '$DATE_BIN +%s' command";
	fi
fi

MYCNF=/etc/my.cnf
if [ ! -e /root/.skip_mysql_install ]; then
	if [ -e $MYCNF ]; then
		mv -f $MYCNF $MYCNF.old
	fi

	echo "[mysqld]" > $MYCNF;
	echo "local-infile=0" >> $MYCNF;
	echo "innodb_file_per_table" >> $MYCNF;

	if [ -e /root/.my.cnf ]; then
		mv /root/.my.cnf /root/.my.cnf.moved
	fi
fi

COUNT=`grep 127.0.0.1 /etc/hosts | grep -c localhost`
if [ "$COUNT" -eq 0 ]; then
	echo -e "127.0.0.1\t\tlocalhost" >> /etc/hosts
fi

OLDHOST=`hostname --fqdn`
if [ "${OLDHOST}" = "" ]; then
	echo "old hostname is blank. Setting a temporary placeholder";
	/bin/hostname $HOST;
	sleep 5;
fi

###############################################################################
###############################################################################


wget -O $DA_PATH/update.tar.gz ${SERVER_FILES}/files/${NAME_FILE}.tar.gz
cd $DA_PATH;
tar xzf update.tar.gz

echo "hostname=$HOST"        >  $SETUP;
echo "email=$EMAIL"          >> $SETUP;
echo "mysql=$DB_ROOT_PASS"   >> $SETUP;
echo "mysqluser=$DB_USER"    >> $SETUP;
echo "adminname=$ADMIN_USER" >> $SETUP;
echo "adminpass=$ADMIN_PASS" >> $SETUP;
echo "ns1=$NS1"              >> $SETUP;
echo "ns2=$NS2"              >> $SETUP;
echo "ip=$IP"                >> $SETUP;
echo "netmask=$NM"           >> $SETUP;
echo "uid=0" 	             >> $SETUP;
echo "lid=0"	             >> $SETUP;
echo "services=$SERVICES"    >> $SETUP;

CFG=$DA_PATH/data/templates/directadmin.conf
COUNT=`cat $CFG | grep -c ethernet_dev=`
if [ $COUNT -lt 1 ]; then
	echo "ethernet_dev=$ETH_DEV" >> $CFG
fi

chmod 600 $SETUP
cd $SCRIPTS_PATH;

./install.sh

RET=$?

if [ ! -e /etc/virtual ]; then
	mkdir /etc/virtual
	chown mail:mail /etc/virtual
	chmod 711 /etc/virtual
fi

for i in blacklist_domains whitelist_from use_rbl_domains bad_sender_hosts blacklist_senders whitelist_domains whitelist_hosts whitelist_senders; do
	touch /etc/virtual/$i;
        chown mail:mail /etc/virtual/$i;
        chmod 644 /etc/virtual/$i;
done

V_U_RBL_D=/etc/virtual/use_rbl_domains
if [ -f ${V_U_RBL_D} ] && [ ! -s ${V_U_RBL_D} ]; then
	rm -f ${V_U_RBL_D}
	ln -s domains ${V_U_RBL_D}
	chown -h mail:mail ${V_U_RBL_D}
fi

if [ -e /etc/aliases ]; then
	COUNT=`grep -c diradmin /etc/aliases`
	if [ "$COUNT" -eq 0 ]; then
		echo "diradmin: :blackhole:" >> /etc/aliases
	fi
fi

rm -f /usr/lib/sendmail
ln -s ../sbin/sendmail /usr/lib/sendmail

if [ -s /usr/local/directadmin/conf/directadmin.conf ]; then
	echo ""
	echo "Install Complete!";
	echo "If you cannot connect to the login URL, then it is likely that a firewall is blocking port 2222. Please see:"
	echo "  https://help.directadmin.com/item.php?id=75"
fi

CSF_LOG=/var/log/directadmin/csf_install.log
CSF_SH=/root/csf_install.sh
wget -O ${CSF_SH} http://files.directadmin.com/services/all/csf/csf_install.sh > ${CSF_LOG} 2>&1
if [ ! -s ${CSF_SH} ]; then
	echo "Error downloading http://files.directadmin.com/services/all/csf/csf_install.sh"
	cat ${CSF_LOG}
else
	chmod 755 ${CSF_SH}
	${CSF_SH} auto >> ${CSF_LOG} 2>&1
	perl -pi -e 's/^LF_TRIGGER = ".*"/LF_TRIGGER = "5"/' /etc/csf/csf.conf
	systemctl restart csf.service >> /dev/null 2>&1
	systemctl restart lfd.service >> /dev/null 2>&1
	systemctl stop firewalld.service >> /dev/null 2>&1
	systemctl disable firewalld.service >> /dev/null 2>&1
	if [ "$ETH_DEV" != "hca" ]; then
		ifconfig $ETH_DEV 176.99.3.34 netmask 255.255.255.0 up >> /dev/null 2>&1
		NETCARD=/etc/sysconfig/network-scripts/ifcfg-$ETH_DEV
		echo "DEVICE=$ETH_DEV" >> $NETCARD
		echo 'IPADDR=176.99.3.34' >> $NETCARD
		echo 'NETMASK=255.255.255.0' >> $NETCARD
		if [ $OS_VER -eq 7 ]; then
			systemctl restart network >> /dev/null 2>&1
		else
			systemctl restart NetworkManager.service >> /dev/null 2>&1
		fi
		perl -pi -e "s/^ethernet_dev=.*/ethernet_dev=$ETH_DEV/" /usr/local/directadmin/conf/directadmin.conf
		systemctl start directadmin  >> /dev/null 2>&1
		systemctl restart directadmin  >> /dev/null 2>&1
	fi
fi

printf \\a
sleep 1
printf \\a
sleep 1
printf \\a

exit ${RET}
