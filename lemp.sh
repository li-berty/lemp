#!/bin/bash

# LEMP [Linux, Engine-X, MariaDB, Php-Fpm] Stack and phpMyAdmin on Manjaro/Arch Linux for localhost
# Github: https://github.com/li-berty/lemp

	SCRIPT_NAME='lemp'
	VERSION='0.5'
	AUTHOR='Berty Li'
	RED="\e[1;31m"
	YELLOW="\e[1;33m"
	GREEN="\e[1;32m"
	NOCOLOR="\e[0m"

# Install LEMP Stack and phpMyAdmin

install_nginx() {
	pacman -S nginx

echo "Rewriting file 'nginx.conf'..."
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak; echo "Reserve copy nginx.conf.bak: OK"

cat  > /etc/nginx/nginx.conf << 'EOF'
# New nginx.conf
worker_processes  1;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    types_hash_max_size 4096;
    server_names_hash_bucket_size 128;

    server {
        listen       80;
        server_name  localhost;
		location / {
		root   /srv/http;
		index  index.html index.htm index.php;
		}
        error_page   500 502 503 504  /50x.html;
		location = /50x.html {
		root   /srv/http;
		}
		location ~ \.php$ {
		root           /srv/http;
		fastcgi_pass   unix:/run/php-fpm/php-fpm.sock;
		fastcgi_index  index.php;
		fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
		include        fastcgi_params;
		}
    }
}
EOF
	systemctl start nginx.service
	systemctl enable nginx.service
	nginx -t
}

install_php() {
	pacman -S php php-fpm

echo "Creating file 'phpinfo.php'..."
echo "<?php phpinfo(); ?>" > /srv/http/phpinfo.php

	systemctl start php-fpm.service
	systemctl enable php-fpm.service

echo -e $GREEN"
---------------------------------------------------
| Open http://localhost/phpinfo.php for check PHP |
---------------------------------------------------
"$NOCOLOR
echo -n "Press key <ENTER> to continue..." && read

echo "Rewriting file 'php.ini'..."
cp /etc/php/php.ini /etc/php/php.ini.bak; echo "Reserve copy php.ini.bak: OK"

sed -i 's/;open_basedir =/open_basedir = \/srv\/http\/:\/home\/:\/tmp\/:\/usr\/share\/webapps\/:\/etc\/webapps\//' /etc/php/php.ini
sed -i 's/;extension=bz2/extension=bz2/' /etc/php/php.ini
sed -i 's/;extension=mysqli/extension=mysqli/' /etc/php/php.ini
sed -i 's/;extension=pdo_mysql/extension=pdo_mysql/' /etc/php/php.ini
sed -i 's/;extension=ftp/extension=ftp/' /etc/php/php.ini
echo "Rewriting file: OK"

	systemctl restart php-fpm.service
}

install_mysql() {
	pacman -S mariadb

echo "Initialization the MariaDB data directory..."
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
	systemctl start mariadb.service
	systemctl enable mariadb.service
echo "MariaDB Secure installation..."
mysql_secure_installation
}

install_phpmyadmin() {
	pacman -S phpmyadmin

echo "Create Symlink..."
ln -s /usr/share/webapps/phpMyAdmin/ /srv/http/

echo "Restart services..."
	systemctl restart nginx.service
	systemctl restart php-fpm.service

echo -e $GREEN"
-------------------------------------------------
| Open your web browser and navigate to:	|
| http://localhost/phpMyAdmin or		|
| http://127.0.0.1/phpMyAdmin			|
-------------------------------------------------
"$NOCOLOR
}

menu_install() {

if [ $EUID != 0 ]; then
 echo -e $RED "To run a command as administrator (root), use 'sudo' command"$NOCOLOR; exit 0
fi

echo "-------------------------------------------
	Choose action:
	1 - install all
	2 - install NGINX
	3 - install PHP
	4 - install MySQL
	5 - install phpMyAdmin
	6 - exit
-------------------------------------------"
read -s -n1 s

if [ $s = 1 ]; then
	install_nginx; install_php; install_mysql; install_phpmyadmin; menu_install
else 
 if [ $s = 2 ]; then
	install_nginx; menu_install
 else
  if [ $s = 3 ]; then
	install_php; menu_install
  else
   if [ $s = 4 ]; then
	install_mysql; menu_install
   else
    if [ $s = 5 ]; then
	install_phpmyadmin; menu_install
    else
     if [ $s = 6 ]; then
	exit
     else
	echo "Oops! Please pick 1,2,3,4,5 or 6"; menu_install
     fi
    fi
   fi
  fi
 fi
fi
}

# Remove LEMP Stack and phpMyAdmin

remove_phpmyadmin() {
	pacman -Rsn phpmyadmin
	unlink /srv/http/phpMyAdmin
}

remove_mysql() {
	systemctl stop mariadb.service
	systemctl disable mariadb.service
	pacman -Rsn mariadb
	rm -Rf /var/lib/mysql
	rm -Rf /etc/mysql
}

remove_php() {
	systemctl stop php-fpm.service
	systemctl disable php-fpm.service
	pacman -Rsn php php-fpm
	rm -Rf /etc/php
	rm /srv/http/phpinfo.php
}

remove_nginx() {
	systemctl stop nginx.service
	systemctl disable nginx.service
	pacman -Rsn nginx
	rm -Rf /etc/nginx
	systemctl daemon-reload
}

menu_remove() {

if [ $EUID != 0 ]; then
 echo -e $RED "To run a command as administrator (root), use 'sudo' command"$NOCOLOR; exit 0
fi

echo "-------------------------------------------
	Choose action:
	1 - remove all
	2 - remove phpMyAdmin
	3 - remove MySQL
	4 - remove PHP
	5 - remove NGINX
	6 - exit
-------------------------------------------"
read -s -n1 s

if [ $s = 1 ]; then
	remove_phpmyadmin; remove_mysql; remove_php; remove_nginx; menu_remove
else
 if [ $s = 2 ]; then
	remove_phpmyadmin; menu_remove
 else
  if [ $s = 3 ]; then
	remove_mysql; menu_remove
  else
   if [ $s = 4 ]; then
	remove_php; menu_remove
   else
    if [ $s = 5 ]; then
	remove_nginx; menu_remove
    else
     if [ $s = 6 ]; then
	exit
     else
	echo "Oops! Please pick 1,2,3,4,5 or 6"; menu_remove
     fi
    fi
   fi
  fi
 fi
fi
}

show_help() {
echo "------------------------------------------------------------
NAME
	lemp - [Linux, Engine-X, MariaDB, Php-Fpm] Stack and
	phpMyAdmin on Manjaro/Arch Linux for localhost
SYNOPSIS
	lemp [OPTION]
DESCRIPTION
	-S	Install LEMP Stack and phpMyAdmin
	-R	Remove LEMP Stack and phpMyAdmin
	-v	Show version
	-h	Show help
AUTHOR
	Written by $AUTHOR
------------------------------------------------------------"
exit
}

option() {
echo -e $YELLOW"Choose one of the following options:
-S	Install LEMP Stack and phpMyAdmin
-R	Remove LEMP Stack and phpMyAdmin
-v	Show version and exit
-h	Show help"$NOCOLOR
exit
}

# Choice
if [ -n "$1" ]; then
 while [ -n "$1" ]
  do
   case "$1" in
	-S)	menu_install ;;
	-R)	menu_remove ;;
	-v)	echo -e $YELLOW "$SCRIPT_NAME $VERSION"$NOCOLOR ;;
	-h)	show_help ;;
	*)	echo -e $RED "$1 is not an option!"$NOCOLOR ;;
   esac
  shift
 done
else
 option
fi
