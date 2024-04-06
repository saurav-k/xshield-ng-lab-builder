#!/bin/bash
set -x
hostnamectl set-hostname ${hostname}

ip route add default via ${gk_lan_ip}
ip route add 169.254.169.254 via ${gk_lan_default_gw}



