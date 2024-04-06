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

wget https://ct-xshield-lab-assets.s3.amazonaws.com/infra/agent.sh
sed -i "s/{SIEM_IP}/${siem_ip}/;s/{ASSETMGR_IP}/${assetmgr_ip}/" agent.sh
install -D agent.sh /var/opt/acme/agent.sh
(crontab -l 2>/dev/null; echo "*/5 * * * *  /var/opt/acme/agent.sh" ) | crontab -
