#!/bin/bash

set -e

# Configurable variables
REGION="us-east-2"
AMI_ID="ami-0cfde0ea8edd312d4"
INSTANCE_TYPE="t3.micro"
KEY_NAME="vxg-key"
SECURITY_GROUP_NAME="vxg-sg"
INSTANCE_NAME="vxg-k3s-instance"

echo "[*] Creating SSH key pair: $KEY_NAME"
aws ec2 create-key-pair \
  --region "$REGION" \
  --key-name "$KEY_NAME" \
  --query 'KeyMaterial' \
  --output text > "${KEY_NAME}.pem"
chmod 400 "${KEY_NAME}.pem"

echo "[*] Creating security group: $SECURITY_GROUP_NAME"
SG_ID=$(aws ec2 create-security-group \
  --region "$REGION" \
  --group-name "$SECURITY_GROUP_NAME" \
  --description "Allow SSH and HTTP" \
  --query 'GroupId' \
  --output text)

echo "[*] Adding SSH and HTTP ingress rules..."
aws ec2 authorize-security-group-ingress \
  --region "$REGION" \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --region "$REGION" \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

echo "[*] Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --region "$REGION" \
  --image-id "$AMI_ID" \
  --count 1 \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "[*] Waiting for EC2 instance to be running..."
aws ec2 wait instance-running --region "$REGION" --instance-ids "$INSTANCE_ID"

echo "[*] Getting Public IP..."
PUBLIC_IP=$(aws ec2 describe-instances \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "[+] EC2 instance created successfully!"
echo "Instance ID: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo "SSH using: ssh -i ${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
