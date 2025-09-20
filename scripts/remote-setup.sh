#!/bin/bash
set -euo pipefail

# Set KUBECONFIG to work without sudo
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "[*] Updating packages and installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y curl helm

# Install k3s if not already installed
if ! command -v k3s &> /dev/null; then
  echo "[*] Installing k3s..."
  curl -sfL https://get.k3s.io | sh -
else
  echo "[+] k3s is already installed"
fi

# Wait for node to be Ready
echo "[*] Waiting for k3s node to be ready..."
ATTEMPTS=0
until kubectl get nodes 2>/dev/null | grep -q ' Ready '; do
  ((ATTEMPTS++))
  if [ "$ATTEMPTS" -gt 20 ]; then
    echo "[!] Node not ready after multiple attempts, exiting."
    exit 1
  fi
  sleep 5
done

# Copy kubeconfig to ubuntu user home
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/kubeconfig.yaml
chown ubuntu:ubuntu /home/ubuntu/kubeconfig.yaml

export KUBECONFIG=/home/ubuntu/kubeconfig.yaml

echo "[*] Adding Helm repos..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create namespace if not exists
kubectl get namespace monitoring &>/dev/null || kubectl create namespace monitoring

# Deploy sample app (NGINX)
echo "[*] Deploying NGINX using Helm..."
helm upgrade --install nginx-release oci://registry-1.docker.io/bitnamicharts/nginx \
  --namespace default \
  --create-namespace

# Deploy Prometheus
echo "[*] Deploying Prometheus..."
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --create-namespace

# Wait for Prometheus pods to be ready
kubectl rollout status deployment prometheus-server -n monitoring

# Sample metric collection
echo "[*] Sample Prometheus metrics:"
kubectl get pods -n monitoring
kubectl get svc -n monitoring

echo "[*] Setup complete. You can port-forward Prometheus using:"
echo "kubectl port-forward svc/prometheus-server 9090:80 -n monitoring"