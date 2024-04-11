#!/bin/bash
set -x
sudo hostnamectl set-hostname ${hostname}
apt update
apt install -y mysql-server
sed -i "s/^bind-address.*/bind-address\t\t= 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql
cd /tmp
wget https://ct-xshield-lab-assets.s3.amazonaws.com/wordpress/config.sql
sed -i "s/{PASSWORD}/${password}/" config.sql

mysql -u root < config.sql
mysql -u root -e "flush privileges;"

rm config.sql
