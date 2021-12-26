#!/bin/bash
# LEMP [Linux, Engine-X, MariaDB, Php-Fpm] Stack and phpMyAdmin on Manjaro/Arch Linux for localhost

R='\e[1;31m' G='\e[1;32m' Y='\e[1;33m' N='\e[0m'

if [ $EUID -ne 0 ]; then
 echo -e $R"Run this script as root (sudo)"$N; exit
fi

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

echo -e $G"
---------------------------------------------------
| Open http://localhost/phpinfo.php for check PHP |
---------------------------------------------------
"$N
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

echo -e $G"
-------------------------------------------------
| Open your web browser and navigate to:	|
| http://localhost/phpMyAdmin or		|
| http://127.0.0.1/phpMyAdmin			|
-------------------------------------------------
"$N
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

menu() {
while :
do
echo -e "------------------------------------------------------
	Choose one of the following options:

1 - install all			6 - remove phpMyAdmin
2 - install NGINX		7 - remove MySQL
3 - install PHP			8 - remove PHP
4 - install MySQL		9 - remove NGINX
5 - install phpMyAdmin		0 - remove all
------------------------------------------------------
	Pick <any key> to exit"

read -s -n1 digit

if [[ $digit = 1 ]]; then
		install_nginx; install_php; install_mysql; install_phpmyadmin; menu
elif [[ $digit = 2 ]]; then
		install_nginx; menu
 elif [[ $digit = 3 ]]; then
		install_php; menu
  elif [[ $digit = 4 ]]; then
		install_mysql; menu
   elif [[ $digit = 5 ]]; then
		install_phpmyadmin; menu
    elif [[ $digit = 6 ]]; then
		remove_phpmyadmin; menu
     elif [[ $digit = 7 ]]; then
		remove_mysql; menu     
      elif [[ $digit = 8 ]]; then
		remove_php; menu
       elif [[ $digit = 9 ]]; then
		remove_nginx; menu
        elif [[ $digit = 0 ]]; then
		remove_phpmyadmin; remove_mysql; remove_php; remove_nginx; menu
         else
		clear; break
fi
done
}

clear; menu
