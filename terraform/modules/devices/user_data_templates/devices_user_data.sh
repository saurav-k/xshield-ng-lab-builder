#!/bin/bash
set -x
hostnamectl set-hostname ${hostname}
apt-get update
apt-get install -y traceroute

# Add a new default route via the Gatekeeper
ip route add default via ${gk_lan_ip} metric 10

# Add routes to AWS services via the default GW
ip route add 169.254.169.254 via ${gk_lan_default_gw}

# Delete the existing /24 route
ip route | grep "/24" | xargs ip route delete

# Delete the existing default route
ip route delete default via ${gk_lan_default_gw}

# Create a listener to simulate a database
cat > /etc/systemd/system/dbsim.service <<EOT
[Unit]
Description=Listener for DB simulator
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/nc -nlvk -p 1433
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOT

systemctl start dbsim
systemctl enable dbsim

# End of database simulator

# Create a script that will connect to all database "servers"
# Note that we escape the $ if we don't want terraform to expand it!

mkdir -p /opt/acme
cat > /opt/acme/dbsim.sh <<EOX
#!/bin/bash

date > /var/log/dbsim.log

# Loop through IP addresses and execute netcat
for i in \$(seq 1 ${count}); do
    ip_address="${ip_prefix}\$i"
    nc -vz "\$ip_address" 1433 >> /var/log/dbsim.log 2>&1
done
EOX

# Install this in crontab
chmod +x /opt/acme/dbsim.sh
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/acme/dbsim.sh" ) | crontab -








