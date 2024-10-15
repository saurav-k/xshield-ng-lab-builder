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
sed -i "s/crm_db_host/${db_endpoint}/;s/crm_db_password/${crm_password}/" /var/www/html/SuiteCRM/config.php

sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/SuiteCRM|g' /etc/apache2/sites-enabled/000-default.conf
sudo systemctl restart apache2.service
# Append referer entry to config_override.php in SugarCRM
CONFIG_OVERRIDE_PATH="/var/www/html/SuiteCRM/config_override.php"
if [ ! -f "$CONFIG_OVERRIDE_PATH" ]; then
    echo "<?php" > $CONFIG_OVERRIDE_PATH
fi
echo "\$sugar_config['http_referer']['list'][] = ${web_gateway_ip};" >> $CONFIG_OVERRIDE_PATH
