# VXG DevOps Task – EC2 + k3s + Helm

This repo automates provisioning an EC2 instance on AWS, installs k3s, deploys a sample Nginx app and Prometheus using Helm, and validates metric collection.

## Stack
- AWS EC2 (via AWS CLI)
- k3s (lightweight Kubernetes)
- Helm (app + Prometheus deployment)
- Prometheus (metrics)

## Setup Steps

1. Clone the repo
2. Run `bash scripts/deploy.sh`
3. Visit `http://<EC2_PUBLIC_IP>` to view Nginx
4. Port-forward Prometheus if needed
...

## Sample Metric Output
(Screenshot)

## Notes
- Security group allows SSH + HTTP only
- Prometheus is deployed in the `monitoring` namespace
