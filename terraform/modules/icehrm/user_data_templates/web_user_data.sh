#!/bin/bash
set -x
sudo hostnamectl set-hostname ${hostname}
apt update
apt install -y haproxy

cd /tmp
wget https://ct-xshield-lab-assets.s3.amazonaws.com/hrm/haproxy_ext.cfg
cat haproxy_ext.cfg >> /etc/haproxy/haproxy.cfg
sed -i "s/{APP_IP}/${app_ip}/" /etc/haproxy/haproxy.cfg
systemctl restart haproxy
