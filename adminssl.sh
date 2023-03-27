#!/bin/bash

DA_PATH=/usr/local/directadmin
TEMP_FILENAME="/var/www/html/.tmp"

ip=`wget -q -O - http://myip.directadmin.com`
domain=`cat $DA_PATH/scripts/setup.txt | grep -e "hostname=" | cut -d"=" -f2`
regex="^[[:alpha:]][[:alnum:]\-]*\.[[:alpha:]][[:alnum:]\-]*\.[[:alpha:]][[:alnum:]\-]*$"

yesno="n"
while [ "$yesno" = "n" ]; do
{
	echo -n "Do you want to install ssl admin for $domain or other domain? (y,n): ";
	read yesno;

	while [ "$yesno" = "n" ]; do
	{
		echo -n "Please input your subdomain hostname (Ex: server.test.com): ";
		read domain;

		if [[ "$domain" =~ $regex ]]; then
			yesno="y";
		else
			echo "The subdomain $domain you entered is not valid!";
			echo ""
		fi
	}
	done;
}
done;

yesno="n"
while [ "$yesno" = "n" ]; do
{
	echo -n "Did you point subdomain $domain to ip server $ip with A record? (y,n): ";
	read yesno;
	if [ "$yesno" = "n" ]; then
		echo "Please point subdomain $domain to ip server $ip with A record then try again!"
		exit;
	fi
}
done;

echo "" > $TEMP_FILENAME
if ! curl --connect-timeout 40 -k --silent -I -L -X GET  "http://${domain}/.tmp" 2>/dev/null | grep -m1 -q 'HTTP.*200'; then
	echo "Your subdomain $domain not point to ip server $ip!"
	echo "Please point subdomain $domain to ip server $ip with A record then try again!"
	exit;
else
	perl -pi -e "s/servername=.*/servername=${domain}/" ${DA_PATH}/conf/directadmin.conf
	$DA_PATH/scripts/letsencrypt.sh request_single ${domain} 4096
	if [ $? -gt 0 ]; then
		echo "Error to get ssl for admin page!"
	else
		ssl_redirect_host=`$DA_PATH/directadmin set ssl_redirect_host ${domain} | grep "ssl_redirect_host="`
		if [ -n "$ssl_redirect_host" ]; then
			echo $ssl_redirect_host
		else
			$DA_PATH/directadmin set force_hostname ${domain}
		fi
		systemctl restart directadmin
		echo "Success to get ssl for admin page!"
	fi
	printf \\a
	sleep 1
	printf \\a
	sleep 1
	printf \\a
fi
