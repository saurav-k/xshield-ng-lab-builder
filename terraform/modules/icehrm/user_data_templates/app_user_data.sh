#!/bin/bash
set -x
sudo hostnamectl set-hostname ${hostname}
apt update
sudo apt install -y php php-mysql php-net-smtp php-gd memcached

sed -i "s/^bind-address.*/bind-address\t\t= 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql
cd /tmp
wget https://ct-xshield-lab-assets.s3.amazonaws.com/hrm/icehrm_v32.4.0.OS.tar.gz
wget https://ct-xshield-lab-assets.s3.amazonaws.com/hrm/config.php
tar xvzf icehrm_v32.4.0.OS.tar.gz -C /var/www
mv /var/www/icehrm_v32.4.0.OS /var/www/icehrm

sed -i "s/hrms_password/${password}/;s/hrm_db_ip/${db_ip}/" config.php
mv config.php /var/www/icehrm/app

chown -R www-data:www-data /var/www/icehrm/app
chmod 755 /var/www/icehrm/app

sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/icehrm|g' /etc/apache2/sites-enabled/000-default.conf
sudo systemctl restart apache2.service

wget https://ct-xshield-lab-assets.s3.amazonaws.com/infra/agent.sh
sed -i "s/{SIEM_IP}/${siem_ip}/;s/{ASSETMGR_IP}/${assetmgr_ip}/" agent.sh
install -D agent.sh /var/opt/acme/agent.sh
(crontab -l 2>/dev/null; echo "*/5 * * * *  /var/opt/acme/agent.sh" ) | crontab -