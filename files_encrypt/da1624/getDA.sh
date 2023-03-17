#!/bin/sh

FILE=/usr/local/directadmin/update.tar.gz
DA_BIN=/usr/local/directadmin/directadmin										 

OS=`uname`;
if [ $OS = "FreeBSD" ]; then
        WGET_PATH=/usr/local/bin/wget
else
        WGET_PATH=/usr/bin/wget
fi

NAME_FILE="da-1624-centos7.tar.gz"
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

#mv ${FILE}.temp ${FILE}
cd /usr/local/directadmin
tar xvzf update.tar.gz
if [ $? -ne 0 ]; then
	echo "Extraction error."
	exit 77
fi

${DA_BIN} p
./scripts/update.sh
echo 'action=directadmin&value=restart' >> /usr/local/directadmin/data/task.queue

echo "Update Successful."

exit 0;					   
