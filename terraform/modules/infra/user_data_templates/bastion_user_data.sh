#!/bin/bash
set -x
sudo hostnamectl set-hostname ${hostname}

apt update

cd /tmp

# Vulnerability scanner simulator
apt install -y nmap netcat
mkdir -p /opt/acme
echo "${nmap_subnets}" > /opt/acme/subnets
(crontab -l 2>/dev/null; echo "0 */1 * * * nmap -sU -sS -S ${vuln_scanner_ip} -iL /opt/acme/subnets  > /var/log/scanner.out" ) | crontab -

# Listener for SIEM simulator (Splunk)
wget https://ct-xshield-lab-assets.s3.amazonaws.com/infra/siem.service
sed -i "s/{LISTEN_IP}/${siem_ip}/" siem.service
mv siem.service /etc/systemd/system/siem.service
systemctl start siem
systemctl enable siem

# Listener for Asset Mgr simulator (Tanium)
wget https://ct-xshield-lab-assets.s3.amazonaws.com/infra/assetmgr.service
sed -i "s/{LISTEN_IP}/${asset_mgr_ip}/" assetmgr.service
mv assetmgr.service /etc/systemd/system/assetmgr.service
systemctl start assetmgr
systemctl enable assetmgr

