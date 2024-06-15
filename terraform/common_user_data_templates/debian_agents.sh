apt install -y netcat
wget https://ct-xshield-lab-assets.s3.amazonaws.com/infra/agent.sh
sed -i "s/{SIEM_IP}/${siem_ip}/;s/{ASSETMGR_IP}/${assetmgr_ip}/" agent.sh
install -D agent.sh /opt/acme/agent.sh
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

