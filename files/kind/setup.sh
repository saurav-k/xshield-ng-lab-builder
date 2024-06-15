#!/bin/bash
#
# Pre-reqs:
#    docker, kind, kubectl, helm are installed
#    metallb-config.yaml is in user ubuntu's home directory
#    the Xshield config map patch is in the home directory
# 
# This script is being run as user ubuntu
#
# (C) 2024 ColorTokens Inc.
# Venky Raju
#
set -x

# Enter ubuntu's home dir
cd $HOME

# Create a custom network for kind
docker network create --subnet 172.20.0.0/16 kind

# Create the K8s cluster
kind create cluster --name us-west

# Download and install istio
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.22.1 TARGET_ARCH=x86_64 sh -
export PATH=$PWD/istio-1.22.1/bin:$PATH
istioctl install --set profile=demo -y

# Deploy MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s
kubectl apply -f metallb-config.yaml

# Now install the sample application
kubectl create ns webstore
kubectl label namespace webstore istio-injection=enabled
kubectl apply -f istio-1.22.1/samples/bookinfo/platform/kube/bookinfo.yaml -n webstore
kubectl apply -f istio-1.22.1/samples/bookinfo/networking/bookinfo-gateway.yaml -n webstore

# Deploy the Xshield container agent
kubectl create namespace ct-system
export HELM_EXPERIMENTAL_OCI=1
helm -n ct-system install ct-contsec {OCR_URI} --version {VERSION} \
  --set global.colortokensDomainSuffix={XS_DOMAIN} --set global.clusterIdentifier=uswest-prod \
  --set global.colortokensAuthKey={XS_DEPLOYMENT_KEY} --set global.service.classicMode="false"

# Get the current istio config map
kubectl get configmap istio -n istio-system -o yaml > orig.yaml

# Merge the Xshield requirements
python3 yaml_patch.py

# Apply the updated config map
kubectl apply -f new.yaml -n istio-system

# Restart istio services
kubectl -n istio-system rollout restart deploy

# Inject istio and opa side cars
kubectl label namespace webstore istio-injection=enabled ct-enforcement=enabled

# Restart application services
kubectl rollout restart deploy -n webstore

# Allow web traffic forwarding from the gateway to the Istio ingress gateway
sudo iptables -I FORWARD -s {WEB_GW_IP} -d 172.20.255.210 -m conntrack --ctstate NEW -j ACCEPT