#/bin/bash
set -x

my_public_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
cd /var/www/html
{
    while :; do
        if /tmp/wp core config --allow-root --dbhost="{DB_IP}" --dbname="wordpress_db" \
            --dbuser="wordpress_user" --dbpass="{PASSWORD}"; then
            chmod 600 wp-config.php
            chown -R www-data:www-data *
            break
        fi
        echo "Will retry in 30 seconds"
        sleep 30
    done

    while :; do
        if /tmp/wp core install --allow-root --url="https://${my_public_ip}" --title="Acme Corp" \
            --admin_name=admin --admin_password="{PASSWORD}" --admin_email=you@example.com;  then
            break
        fi
        echo "Will retry in 30 seconds"
        sleep 30
    done
} > /var/log/wp-install.log 2>&1    