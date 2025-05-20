#!/bin/bash

# Check if server IP is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <EC2_SERVER_IP> [SSH_KEY_PATH]"
  echo "Example: $0 1.2.3.4 ~/.ssh/aws-key.pem"
  exit 1
fi

SERVER_IP=$1
SSH_KEY=${2:-~/.ssh/aws-key.pem}

# Create .kube directory if it doesn't exist
mkdir -p ~/.kube

# Copy kubeconfig from server
echo "Copying kubeconfig from server..."
ssh -i $SSH_KEY ubuntu@$SERVER_IP "sudo cat /etc/rancher/k3s/k3s.yaml" > ~/.kube/config-k3s-aws

# Update server address in kubeconfig
echo "Updating server address in kubeconfig..."
sed -i "s/127.0.0.1/$SERVER_IP/g" ~/.kube/config-k3s-aws

# Set KUBECONFIG environment variable
echo "export KUBECONFIG=~/.kube/config-k3s-aws" > ~/.kube/k3s-aws-env

echo "Kubeconfig setup complete!"
echo "To use the kubeconfig, run:"
echo "source ~/.kube/k3s-aws-env"
echo "Then verify with:"
echo "kubectl get nodes"