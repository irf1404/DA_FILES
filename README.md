N@lled By: Nguyễn Trung Hậu<br>
Email: ken.hdpro@gmail.com<br>
Facebook: http://fb.com/haunguyenckc<br>
Directadmin 1.604 đã được N@ll chỉ cài được cho centOS 7 64bit

# INSTALL DIRECTADMIN ONLY CENTOS7 64BIT
```
# Install command for Directadmin 1604 only centOS7 x64
yum -y install wget && wget --no-cache -O setup.sh "https://raw.githubusercontent.com/irf1404/DA_FILES/master/da-1604-centos7.sh" > tmp 2>&1
chmod +x setup.sh

# Install command for Directadmin 1620 only centOS7 x64
yum -y install wget && wget --no-cache -O setup.sh "https://raw.githubusercontent.com/irf1404/DA_FILES/master/da-1620-centos7.sh" > tmp 2>&1
chmod +x setup.sh

# Install command for Directadmin 1620 only centOS8 x64
yum -y install wget && wget --no-cache -O setup.sh "https://raw.githubusercontent.com/irf1404/DA_FILES/master/da-1620-centos8.sh" > tmp 2>&1
chmod +x setup.sh

# Install command for Directadmin 1624 only centOS7 x64
yum -y install wget && wget --no-cache -O setup.sh "https://raw.githubusercontent.com/irf1404/DA_FILES/master/da-1624-centos7.sh" > tmp 2>&1
chmod +x setup.sh

# Install command for Directadmin 1624 only centOS8 x64
yum -y install wget && wget --no-cache -O setup.sh "https://raw.githubusercontent.com/irf1404/DA_FILES/master/da-1624-centos8.sh" > tmp 2>&1
chmod +x setup.sh


# Run File setup.sh
./setup.sh m h p i n

option "m": Mode
+ auto: Auto setup version package (Default: Openlitespeed, PHP81, Mariadb)
+ normal: You can select version package with custombuild

option "h": Server hostname (Default: server.test.com)
+ xxx.yyy.zzz (Ex: server.hca.com)

option "p": Password admin
+ You can input password or input: "rand" -> for random password

option "i": IP server
+ Auto detect IP or you can input local ip server (Command: "ip a" to show local ip server)

option "n": Network Card (Default: hca)
+ For using license.key, Directadmin 1604 no needed config option "n", Other Directadmin version needed config "n"
+ Input network card  attached IP Server


Ex: ./setup.sh auto server.domain.com admin@123 1.2.3.4
	(Mode: auto, Server Hostname: server.domain.com, Password: admin@123, IP: 1.2.3.4, Network card: default(hca))

	./setup.sh auto server.domain.com rand ""
	(Mode: auto, Server Hostname: server.domain.com, Random password, IP auto detect, Network card: default(hca))

	./setup.sh normal server.domain.com rand 1.2.3.4 eth0
	(Mode: normal, Server Hostname: server.domain.com, Random password, IP: 1.2.3.4, Network card: eth0:100)

	./setup.sh normal server.domain.com admin@123 "" eth0
	(Mode: normal, Server Hostname: server.domain.com, Password: admin@123, IP auto detect, Network card: eth0:100)
	
	... You can select option!
	
```

# INSTALL SSL FOR ADMINPAGE
```
# Point The Subdomain Server.XXX.YYY to IP Server (A Record)

nano /usr/local/directadmin/conf/directadmin.conf

# Find Key servername=ZZZ And Replace It With Server.XXX.YYY Then Save File => Ctrl + X => Y => Enter

/usr/local/directadmin/scripts/letsencrypt.sh request_single Server.XXX.YYY 4096

/usr/local/directadmin/directadmin set ssl_redirect_host Server.XXX.YYY

systemctl restart directadmin

```

# INSTALL MULTI PHP VERSION
```
cd /usr/local/directadmin/custombuild
./build set php1_release 8.2
./build set php2_release 7.0
./build set php3_release 7.4
./build set php4_release 5.6
./build set php1_mode lsphp
./build set php2_mode lsphp
./build set php3_mode lsphp
./build set php4_mode lsphp
./build php n
./build rewrite_confs

```
