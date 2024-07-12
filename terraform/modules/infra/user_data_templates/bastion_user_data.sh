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
cat > /etc/systemd/system/siem.service <<EOS
[Unit]
Description=Listener for SIEM simulator
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/nc -nlvk -s ${siem_ip} -p 9997
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOS

systemctl start siem
systemctl enable siem

# Listener for Asset Mgr simulator (Tanium)
cat > /etc/systemd/system/assetmgr.service <<EOT
[Unit]
Description=Listener for Asset Manager simulator
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/nc -nlvk -s ${asset_mgr_ip} -p 17472
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOT

systemctl start assetmgr
systemctl enable assetmgr

