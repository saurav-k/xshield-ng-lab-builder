#!/bin/bash

# This script reads configuration parameters from the file config.txt and
# creates the file terraform/terraform.tfvars for Terraform, and xshield/config.json
# for the Xshield API scripts.
#
# Please ensure the contents of config.txt file are correct before you run this
# script, as it follows the garbage-in, garbage-out philosophy.  You have been warned!
# 
# (C) 2024, ColorTokens Inc.
# Venky Raju

rm -f terraform/terraform.tfvars
rm -f terraform/provider.tf
rm -f xshield/config.json


domain=$(grep "^domain=" config.txt | cut -d "=" -f2)
tenantId=$(grep "^tenantId=" config.txt | cut -d "=" -f2)
userId=$(grep "^userId=" config.txt | cut -d "=" -f2)
fingerprint=$(grep "^fingerprint=" config.txt | cut -d "=" -f2)
privateKey=$(grep "^privateKey=" config.txt | cut -d "=" -f2)

if [ -z "$domain" ] || [ -z "$tenantId" ] || [ -z "$userId" ] || [ -z "$fingerprint" ] || [ -z "$privateKey" ]; then
    echo "One or more of (domain, tenantId, userId, fingerprint, privateKey) are undefined"    
    exit 1
fi

echo "Writing xshield/config.json..."
cat > xshield/config.json <<EOC
{
  "domain": "$domain",
  "tenantId": "$tenantId",
  "userId": "$userId",
  "keyConfig": {
    "fingerprint": "$fingerprint",
    "privateKey": "$privateKey",
    "passphrase": ""
  }
}
EOC

owner=$(grep "^owner" config.txt | cut -d "=" -f2)
deployment_key=$(cd xshield && python3 -c "import agents;print(agents.get_deployment_key())")

gk_pkg=$(cd xshield && python3 -c "import agents;print(agents.get_agent_installer('CT_GATEWAY', 'debian', 'x86_64'))")

deb_pkg=$(cd xshield && python3 -c "import agents;print(agents.get_agent_installer('CT_AGENT', 'debian', 'x86_64'))")

win_pkg=$(cd xshield && python3 -c "import agents;print(agents.get_agent_installer('CT_AGENT', 'windows', 'x86_64'))")

if [ -z "$owner" ] || [ -z "$deployment_key" ] || [ -z "$gk_pkg" ] || [ -z "$deb_pkg" ] || [ -z "$win_pkg" ]; then
    echo "One or more of (owner, deployment_key, gk_pkg, deb_pkg, win_pkg ) are undefined"       
    exit 1
fi

echo "Writing terraform/terraform.tfvars..."
cat > terraform/terraform.tfvars <<EOT
owner = "$owner"
xs_domain = "$domain"
xs_deployment_key = "${deployment_key}" 
xs_gatekeeper_pkg_url = "${gk_pkg}" 
xs_agent_debian_pkg_url = "${deb_pkg}"
xs_agent_windows_pkg_url = "${win_pkg}"
xs_container_agent_version = "5.9.0-beta.915"
xs_container_registry_uri = "oci://colortokenspublic.azurecr.io/helm/ct-contsec"
EOT

profile=$(grep "^aws-profile" config.txt | cut -d "=" -f2)
region=$(grep "^aws-region" config.txt | cut -d "=" -f2)

if [ -z "$profile" ] || [ -z "$region" ]; then
    echo "One or more of aws-profile, aws-region are undefined"       
    exit 1
fi

echo "Writing terraform/provider.tf"
cat > terraform/provider.tf <<EOP
provider "aws" {
  profile = "$profile"
  region  = "$region"
}
EOP
