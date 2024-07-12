apt install -y netcat

# Create a script to simulate the SIEM and ASSETMGR agents
cat > /tmp/agent.sh <<EOT
#!/bin/bash
nc -vz ${siem_ip} 9997 2> /var/log/siem.log
nc -vz ${assetmgr_ip} 17472 2> /var/log/assetmgr.log
EOT

install -D /tmp/agent.sh /opt/acme/agent.sh
(crontab -l 2>/dev/null; echo "*/5 * * * *  /opt/acme/agent.sh" ) | crontab -

apt install -y curl libpcap-dev nftables iptables rpcbind rsyslog
systemctl start rsyslog.service
systemctl enable rsyslog.service
systemctl start nftables.service
systemctl enable nftables.service

curl -o /tmp/xshield-monitoring-agent.deb ${xs_agent_debian_pkg_url}
dpkg -i /tmp/xshield-monitoring-agent.deb
/etc/colortokens/ctagent register --domain=${xs_domain} --deploymentKey=${xs_deployment_key} \
    --agentType=server --upgrade=true --enable-vulnerability-scan=true

/etc/colortokens/ctagent start

