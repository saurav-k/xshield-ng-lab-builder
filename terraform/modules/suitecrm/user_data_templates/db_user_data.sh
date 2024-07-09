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

# Create a script to connect to one of the legacy DB servers (randomly)
mkdir -p /opt/acme
cat > /opt/acme/db.sh <<EOT
#!/bin/bash

date > /var/log/db.log
random_num=\$((RANDOM % ${legacy_db_count} + 1))
ip_address="${legacy_db_ip_prefix}\$random_num"

nc -vz \$ip_address 1433 2>> /var/log/db.log
EOT

# Install this in crontab
chmod +x /opt/acme/db.sh
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/acme/db.sh" ) | crontab -