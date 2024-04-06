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

wget https://ct-xshield-lab-assets.s3.amazonaws.com/infra/agent.sh
sed -i "s/{SIEM_IP}/${siem_ip}/;s/{ASSETMGR_IP}/${assetmgr_ip}/" agent.sh
install -D agent.sh /var/opt/acme/agent.sh
(crontab -l 2>/dev/null; echo "*/5 * * * *  /var/opt/acme/agent.sh" ) | crontab -
