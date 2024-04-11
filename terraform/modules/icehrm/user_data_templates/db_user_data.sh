#!/bin/bash
set -x
sudo hostnamectl set-hostname ${hostname}
apt update
apt install -y mysql-server
sed -i "s/^bind-address.*/bind-address\t\t= 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql
cd /tmp
wget https://ct-xshield-lab-assets.s3.amazonaws.com/hrm/user.sql
wget https://ct-xshield-lab-assets.s3.amazonaws.com/hrm/icehrmdb.sql
wget https://ct-xshield-lab-assets.s3.amazonaws.com/hrm/icehrm_master_data.sql
wget https://ct-xshield-lab-assets.s3.amazonaws.com/hrm/icehrm_sample_data.sql

sed -i "s/hrm_password/${password}/" user.sql

mysql -u root mysql < user.sql
mysql -u root -e "flush privileges;"

mysql -u root hrms < icehrmdb.sql
mysql -u root hrms < icehrm_master_data.sql
mysql -u root hrms < icehrm_sample_data.sql

rm icehrmdb.sql icehrm_master_data.sql icehrm_sample_data.sql
