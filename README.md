# K3s Ansible AWS Setup

This repository contains Ansible playbooks and roles to set up a K3s Kubernetes cluster on AWS EC2 instances.

## Prerequisites

- Ansible 8.0+ (ansible-core 2.15+) installed on your local machine
- AWS EC2 instances (1 server, 1 agent) with Ubuntu installed
- SSH access to the EC2 instances with a private key
- Python 3.x installed on your local machine

## Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/k3s-ansible-aws.git
   cd k3s-ansible-aws
   ```

2. Update the inventory.yml file with your EC2 instance IPs:
   ```yaml
   k3s_cluster:
     children:
       server:
         hosts:
           k3s-server:
             ansible_host: <EC2_SERVER_IP>
       agent:
         hosts:
           k3s-agent:
             ansible_host: <EC2_AGENT_IP>
   ```

3. Update the SSH private key path in inventory.yml:
   ```yaml
   ansible_ssh_private_key_file: ~/.ssh/your-aws-key.pem
   ```

4. Generate a secure token and encrypt it with ansible-vault:
   ```bash
   ./scripts/generate_token.sh
   ```
   You'll be prompted to create a vault password. Remember this password as you'll need it when running the playbooks.

5. Verify your setup:
   ```bash
   ansible-inventory --list -i inventory.yml
   ```

## Running the Playbook

Run the playbook to set up the K3s cluster:

```bash
ansible-playbook playbooks/site.yml -i inventory.yml --ask-vault-pass
```

This will:
1. Prepare all nodes with prerequisites
2. Install K3s server on the server node
3. Install K3s agent on the agent node

## Connecting to the K3s Cluster from Your Local Machine

After the playbook completes successfully, follow these steps to connect to your K3s cluster:

1. Copy the kubeconfig from the server node to your local machine:
   ```bash
   mkdir -p ~/.kube
   scp -i ~/.ssh/your-aws-key.pem ubuntu@<EC2_SERVER_IP>:/etc/rancher/k3s/k3s.yaml ~/.kube/config-k3s-aws
   ```

2. Update the server address in the kubeconfig file:
   ```bash
   sed -i 's/127.0.0.1/<EC2_SERVER_IP>/g' ~/.kube/config-k3s-aws
   ```

3. Set the KUBECONFIG environment variable:
   ```bash
   export KUBECONFIG=~/.kube/config-k3s-aws
   ```

4. Verify the connection:
   ```bash
   kubectl get nodes
   ```

   You should see output similar to:
   ```
   NAME         STATUS   ROLES                       AGE     VERSION
   k3s-server   Ready    control-plane,master        5m      v1.30.2+k3s1
   k3s-agent    Ready    worker                      3m      v1.30.2+k3s1
   ```

## Additional Commands

- To view the encrypted token:
  ```bash
  ansible-vault view group_vars/vault.yml
  ```

- To edit the encrypted token:
  ```bash
  ansible-vault edit group_vars/vault.yml
  ```

- To upgrade the K3s cluster:
  ```bash
  ansible-playbook playbooks/upgrade.yml -i inventory.yml --ask-vault-pass
  ```

- To reset/uninstall the K3s cluster:
  ```bash
  ansible-playbook playbooks/reset.yml -i inventory.yml
  ```

## Troubleshooting

- If you encounter SSH connection issues, ensure your security groups allow SSH access from your IP.
- If nodes cannot communicate, check that the security groups allow all traffic between the instances.
- For more detailed logs, add `-v` to your ansible-playbook command.

## Security Considerations

- The token is encrypted with ansible-vault for security.
- Always use private networks for your Kubernetes clusters when possible.
- Restrict access to your EC2 instances using security groups.
- Consider using AWS IAM roles for service accounts for better security.
