#!/bin/bash
sudo hostnamectl set-hostname ${hostname}
apt update
apt install -y haproxy

cd /tmp
wget https://ct-xshield-lab-assets.s3.amazonaws.com/crm/haproxy_ext.cfg
cat haproxy_ext.cfg >> /etc/haproxy/haproxy.cfg
sed -i "s/{PREFIX}/${app_ip_prefix}/" /etc/haproxy/haproxy.cfg
systemctl restart haproxy
rm haproxy_ext.cfg

