#!/bin/bash
set -x
sudo hostnamectl set-hostname ${hostname}
apt-get update
apt-get install -y mysql-server php
sed -i "s/^bind-address.*/bind-address\t\t= 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql
cd /tmp
wget https://ct-xshield-lab-assets.s3.amazonaws.com/crm/suitecrm.sql
wget https://ct-xshield-lab-assets.s3.amazonaws.com/crm/user.sql
wget https://ct-xshield-lab-assets.s3.amazonaws.com/crm/hash.php

sed -i "s/crm_password/${password}/" user.sql
mysql -u root mysql < user.sql

export suitecrm_passwd_hash=`php hash.php "${password}"`
sed -i "s|admin_password_hash|$suitecrm_passwd_hash|" suitecrm.sql
mysql -u root < suitecrm.sql

mysql -u root -e "flush privileges;"
#rm user.sql suitecrm.sql

