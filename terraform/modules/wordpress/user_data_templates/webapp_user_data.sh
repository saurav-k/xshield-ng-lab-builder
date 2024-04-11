#!/bin/bash
set -x
hostnamectl set-hostname ${hostname}
apt update

apt install -y at apache2 php libapache2-mod-php php-mysql \
    php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip
a2enmod ssl
a2enmod headers
a2ensite default-ssl
systemctl restart apache2

cd /tmp
curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o wp
chmod +x wp
cd /var/www/html
rm index.html
/tmp/wp core download --allow-root

cd /tmp
wget https://ct-xshield-lab-assets.s3.amazonaws.com/wordpress/wp-install.sh
sed -i "s/{PASSWORD}/${password}/;s/{DB_IP}/${db_ip}/" wp-install.sh
at now + 2 minutes -f /tmp/wp-install.sh