#!/bin/bash
set -x
hostnamectl set-hostname ${hostname}
apt-get update && apt-get upgrade -y

echo "Installing Docker"
apt-get install ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
usermod -aG docker ubuntu

echo "Installing Kind"
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind

echo "Installing kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
apt-get install helm

# Fetch setup bundle
cd /home/ubuntu
wget https://ct-xshield-lab-assets.s3.amazonaws.com/kind/metallb-config.yaml
wget https://ct-xshield-lab-assets.s3.amazonaws.com/kind/setup.sh
wget https://ct-xshield-lab-assets.s3.amazonaws.com/kind/yaml_patch.py
wget https://ct-xshield-lab-assets.s3.amazonaws.com/kind/yaml_patch.txt
chmod +x setup.sh
chown ubuntu:ubuntu *.py *.yaml *.sh

# Uodate setup.sh
sed -i "s|{OCR_URI}|${xs_container_registry_uri}|" setup.sh
sed -i "s/{VERSION}/${xs_container_agent_version}/" setup.sh
sed -i "s|{XS_DOMAIN}|${xs_domain}|" setup.sh
sed -i "s/{XS_DEPLOYMENT_KEY}/${xs_deployment_key}/" setup.sh
sed -i "s/{WEB_GW_IP}/${web_gw_ip}/" setup.sh


nohup su -c "/home/ubuntu/setup.sh > /tmp/setup.log 2>&1" ubuntu &
