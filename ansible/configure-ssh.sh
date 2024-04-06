#!/bin/bash

pem_file=$(terraform -chdir=../terraform output -raw pem)
bastion_ip=$(terraform -chdir=../terraform output -raw bastion_ip)
cp ssh-config-template ssh-config
sed -i "s|<pem file>|${pem_file}|;s|<bastion ip>|${bastion_ip}|" ssh-config
