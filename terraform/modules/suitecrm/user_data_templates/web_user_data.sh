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

wget https://ct-xshield-lab-assets.s3.amazonaws.com/infra/agent.sh
sed -i "s/{SIEM_IP}/${siem_ip}/;s/{ASSETMGR_IP}/${assetmgr_ip}/" agent.sh
install -D agent.sh /var/opt/acme/agent.sh
(crontab -l 2>/dev/null; echo "*/5 * * * *  /var/opt/acme/agent.sh" ) | crontab -
