#!/bin/bash
sudo hostnamectl set-hostname ${hostname}
apt update
apt install -y apache2 php libapache2-mod-php php-mysql php-fpm php-xml php-zip php-curl php-gd
a2enmod proxy_fcgi setenvif
a2enconf php8.1-fpm
systemctl restart apache2
sed -i "s/^upload_max_filesize.*/upload_max_filesize = 6M/" /etc/php/8.1/fpm/php.ini
service php8.1-fpm restart
cd /tmp
wget https://ct-xshield-lab-assets.s3.amazonaws.com/crm/suitecrm.tgz
tar xvzf suitecrm.tgz -C /var/www/html
chown -R www-data:www-data /var/www/html
sed -i "s/crm_db_host/${db_ip}/;s/crm_db_password/${password}/" /var/www/html/SuiteCRM/config.php

sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/SuiteCRM|g' /etc/apache2/sites-enabled/000-default.conf
sudo systemctl restart apache2.service

wget https://ct-xshield-lab-assets.s3.amazonaws.com/infra/agent.sh
sed -i "s/{SIEM_IP}/${siem_ip}/;s/{ASSETMGR_IP}/${assetmgr_ip}/" agent.sh
install -D agent.sh /var/opt/acme/agent.sh
(crontab -l 2>/dev/null; echo "*/5 * * * *  /var/opt/acme/agent.sh" ) | crontab -
