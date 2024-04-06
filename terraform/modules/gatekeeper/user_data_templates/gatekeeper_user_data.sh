#!/bin/bash
set -x
sudo hostnamectl set-hostname ${hostname}

apt update

cat <<EOT > /root/ctgatekeeper.json
{
    "agent": {
        "type": "gateway",
        "domain": "{domain}",
        "deploymentKey": "{deploymentKey}",
        "autoUpgrade": "true"
    },
    "dhcp": {
        "enabled": "false"
    },
    "interfaces": [
        {
            "name": "{wan_ifname}",
            "type": "WAN",
            "ipAddress": "${gk_wan_ip}/24",
            "dnsServers": [ "4.2.2.2", "8.8.8.8" ],
            "gatewayAddress": "${gk_wan_gw}"
        },
        {
            "name": "{lan_ifname}",
            "type": "LAN",
            "ipAddress": "${gk_lan_ip}/24",
            "gatewayAddress": "${gk_lan_ip}"
        }
    ]
}
EOT

wan_ifname=$(ip -o -4 -br a | grep ${gk_wan_ip} | cut -d " " -f1)
lan_ifname=$(ip -o -4 -br a | grep ${gk_lan_ip} | cut -d " " -f1)

sed -i "s/{wan_ifname}/$wan_ifname/;s/{lan_ifname}/$lan_ifname/" /root/ctgatekeeper.json

