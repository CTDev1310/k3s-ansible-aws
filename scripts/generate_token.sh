#!/bin/bash

# Create directory if it doesn't exist
mkdir -p /home/tien/Develop/Ansible/k3s-ansible-aws/scripts

# Generate a random token
TOKEN=$(openssl rand -base64 64)

# Create a temporary file with the token
cat > /tmp/token.yml << EOF
---
token: "${TOKEN}"
EOF

# Encrypt the token with ansible-vault
ansible-vault encrypt /tmp/token.yml --output=/home/tien/Develop/Ansible/k3s-ansible-aws/group_vars/vault.yml

# Clean up
rm /tmp/token.yml

echo "Token generated and encrypted in group_vars/vault.yml"
echo "Use 'ansible-vault view group_vars/vault.yml' to view the token"
echo "Use 'ansible-vault edit group_vars/vault.yml' to edit the token"
