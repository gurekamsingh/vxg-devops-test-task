#!/bin/bash

set -e

echo "[*] Updating packages..."
sudo apt-get update -y

echo "[*] Installing dependencies (curl, git)..."
sudo apt-get install -y curl git

echo "[*] Installing k3s..."
curl -sfL https://get.k3s.io | sh -

echo "[*] Waiting for k3s to start..."
sleep 15
sudo kubectl get nodes

echo "[*] Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "[*] Adding Helm repos..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "[*] Deploying sample NGINX app..."
helm install my-nginx bitnami/nginx

echo "[*] Deploying Prometheus..."
helm install my-prometheus prometheus-community/prometheus

echo "[*] Waiting for services to be up..."
sleep 30

echo "[*] Getting Prometheus pods and services..."
sudo kubectl get pods -A
sudo kubectl get svc -A

echo "[*] Verifying metric collection..."
sudo kubectl get --raw /metrics || echo "Prometheus metrics endpoint not ready yet."

echo "[+] Setup complete. NGINX and Prometheus are now deployed on k3s!"
