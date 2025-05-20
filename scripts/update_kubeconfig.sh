#!/bin/bash

# This script updates the kubeconfig to use the public IP address of the K3s server

# Set variables
SERVER_IP="54.179.59.102"
SSH_KEY="/Users/tien/.ssh/k8s-ec2-key.pem"
KUBECONFIG_DIR="$HOME/.kube"
KUBECONFIG_FILE="$KUBECONFIG_DIR/config-k3s-aws"
ENV_FILE="$KUBECONFIG_DIR/k3s-aws-env"

# Create .kube directory if it doesn't exist
mkdir -p $KUBECONFIG_DIR

# Copy kubeconfig from server
echo "Copying kubeconfig from server..."
ssh -i $SSH_KEY ubuntu@$SERVER_IP "sudo cat /etc/rancher/k3s/k3s.yaml" > $KUBECONFIG_FILE

# Update server address in kubeconfig
echo "Updating server address in kubeconfig..."
# Use different sed syntax based on OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  sed -i '' "s/127.0.0.1/$SERVER_IP/g" $KUBECONFIG_FILE
  # Add insecure-skip-tls-verify option
  # sed -i '' "/certificate-authority-data/a\\
  #   insecure-skip-tls-verify: true" $KUBECONFIG_FILE
else
  # Linux and others
  sed -i "s/127.0.0.1/$SERVER_IP/g" $KUBECONFIG_FILE
  # Add insecure-skip-tls-verify option
  # sed -i "/certificate-authority-data/a\\    insecure-skip-tls-verify: true" $KUBECONFIG_FILE
fi

# Create environment file
echo "Creating environment file..."
cat > $ENV_FILE << EOF
export KUBECONFIG=$KUBECONFIG_FILE
export CLUSTER_CONTEXT=k3s-aws
EOF

echo "Kubeconfig updated successfully!"
echo "To use the updated kubeconfig, run:"
echo "source $ENV_FILE"
echo "Then you can run kubectl commands, e.g.:"
echo "kubectl get nodes"
