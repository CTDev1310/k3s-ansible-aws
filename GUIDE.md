# Comprehensive Guide: Setting Up K3s Cluster on AWS EC2 with Ansible

This guide provides detailed, step-by-step instructions for setting up a K3s Kubernetes cluster on AWS EC2 instances using Ansible.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS Setup](#aws-setup)
3. [Local Environment Setup](#local-environment-setup)
4. [Ansible Configuration](#ansible-configuration)
5. [Running the Ansible Playbook](#running-the-ansible-playbook)
6. [Connecting to the K3s Cluster](#connecting-to-the-k3s-cluster)
7. [Verifying the Cluster](#verifying-the-cluster)
8. [Troubleshooting](#troubleshooting)
9. [Additional Operations](#additional-operations)

## Prerequisites

- Ansible 8.0+ (ansible-core 2.15+) installed on your local machine
- AWS account with permissions to create EC2 instances
- AWS CLI installed and configured
- SSH key pair for AWS
- Python 3.x installed on your local machine
- kubectl installed on your local machine

## AWS Setup

### 1. Create EC2 Instances

Create two EC2 instances with Ubuntu:

1. **Server Node**:
   - Ubuntu 22.04 LTS
   - t3.medium (2 vCPU, 4 GB RAM) or larger
   - At least 20 GB storage

2. **Agent Node**:
   - Ubuntu 22.04 LTS
   - t3.small (2 vCPU, 2 GB RAM) or larger
   - At least 20 GB storage

### 2. Security Group Configuration

Create a security group with the following rules:

- **Inbound Rules**:
  - SSH (TCP 22) from your IP
  - Kubernetes API (TCP 6443) from your IP
  - All traffic between the instances (use the security group ID as the source)

- **Outbound Rules**:
  - All traffic to anywhere (0.0.0.0/0)

### 3. Assign Security Group

Assign the security group to both EC2 instances.

### 4. Note the Instance IPs

Note the public IP addresses of both instances:
- Server Node IP: `<EC2_SERVER_IP>`
- Agent Node IP: `<EC2_AGENT_IP>`

## Local Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/k3s-ansible-aws.git
cd k3s-ansible-aws
```

### 2. Update the Inventory File

Edit the `inventory.yml` file to include your EC2 instance IPs:

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

  vars:
    ansible_port: 22
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/your-aws-key.pem
    k3s_version: v1.30.2+k3s1
    api_endpoint: "{{ hostvars[groups['server'][0]]['ansible_host'] | default(groups['server'][0]) }}"
    cluster_context: k3s-aws
```

Replace:
- `<EC2_SERVER_IP>` with your server node's public IP
- `<EC2_AGENT_IP>` with your agent node's public IP
- `~/.ssh/your-aws-key.pem` with the path to your AWS SSH key

## Ansible Configuration

### 1. Generate and Encrypt the Token

Generate a secure token and encrypt it with ansible-vault:

```bash
./scripts/generate_token.sh
```

You'll be prompted to create a vault password. Remember this password as you'll need it when running the playbooks.

### 2. Verify Ansible Connectivity

Test the connection to your EC2 instances:

```bash
ansible all -m ping -i inventory.yml
```

If successful, you should see a "pong" response from both instances.

## Running the Ansible Playbook

### 1. Run the Playbook

Run the playbook to set up the K3s cluster:

```bash
ansible-playbook playbooks/site.yml -i inventory.yml --ask-vault-pass
```

Enter the vault password when prompted.

### 2. Monitor the Installation

The playbook will:
1. Prepare all nodes with prerequisites
2. Install K3s server on the server node
3. Install K3s agent on the agent node

This process may take 5-10 minutes to complete.

## Connecting to the K3s Cluster

### 1. Using the Setup Script

The easiest way to connect to your cluster is using the provided script:

```bash
./scripts/setup_kubeconfig.sh <EC2_SERVER_IP> ~/.ssh/your-aws-key.pem
```

Then activate the configuration:

```bash
source ~/.kube/k3s-aws-env
```

### 2. Manual Setup

Alternatively, you can set up the connection manually:

```bash
# Copy kubeconfig from server
mkdir -p ~/.kube
scp -i ~/.ssh/your-aws-key.pem ubuntu@<EC2_SERVER_IP>:/etc/rancher/k3s/k3s.yaml ~/.kube/config-k3s-aws

# Update server address in kubeconfig
sed -i 's/127.0.0.1/<EC2_SERVER_IP>/g' ~/.kube/config-k3s-aws

# Set KUBECONFIG environment variable
export KUBECONFIG=~/.kube/config-k3s-aws
```

## Verifying the Cluster

### 1. Check Nodes

Verify that both nodes are connected and ready:

```bash
kubectl get nodes
```

Expected output:
```
NAME         STATUS   ROLES                       AGE     VERSION
k3s-server   Ready    control-plane,master        5m      v1.30.2+k3s1
k3s-agent    Ready    worker                      3m      v1.30.2+k3s1
```

### 2. Check Pods

Verify that system pods are running:

```bash
kubectl get pods -A
```

All pods should be in the "Running" state.

### 3. Deploy a Test Application

Deploy a simple test application:

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
```

Get the assigned NodePort:
```bash
kubectl get svc nginx
```

Access the application at `http://<EC2_SERVER_IP>:<NodePort>`.

## Troubleshooting

### SSH Connection Issues

- Ensure your security groups allow SSH access from your IP.
- Verify that your SSH key has the correct permissions: `chmod 400 ~/.ssh/your-aws-key.pem`.
- Try connecting manually: `ssh -i ~/.ssh/your-aws-key.pem ubuntu@<EC2_SERVER_IP>`.

### Node Communication Issues

- Ensure your security groups allow all traffic between the instances.
- Check that the token is correctly encrypted and accessible.
- Verify that the API endpoint is correctly set in the inventory.yml file.

### Ansible Playbook Failures

- Run the playbook with increased verbosity: `ansible-playbook playbooks/site.yml -i inventory.yml --ask-vault-pass -vvv`.
- Check the logs on the server: `ssh -i ~/.ssh/your-aws-key.pem ubuntu@<EC2_SERVER_IP> 'sudo journalctl -u k3s'`.

### Kubectl Connection Issues

- Ensure the kubeconfig file has the correct server IP.
- Verify that port 6443 is open in your security group.
- Check that the KUBECONFIG environment variable is correctly set.

## Additional Operations

### Upgrading K3s

To upgrade the K3s version:

1. Update the `k3s_version` in your inventory.yml file.
2. Run the upgrade playbook:
   ```bash
   ansible-playbook playbooks/upgrade.yml -i inventory.yml --ask-vault-pass
   ```

### Resetting the Cluster

To completely reset/uninstall the K3s cluster:

```bash
ansible-playbook playbooks/reset.yml -i inventory.yml
```

### Adding More Nodes

To add more agent nodes:

1. Create new EC2 instances.
2. Add them to the `agent` section in your inventory.yml file.
3. Run the playbook again:
   ```bash
   ansible-playbook playbooks/site.yml -i inventory.yml --ask-vault-pass
   ```

### Backing Up Etcd

K3s uses SQLite by default, which is stored at `/var/lib/rancher/k3s/server/db/` on the server node. To back it up:

```bash
ssh -i ~/.ssh/your-aws-key.pem ubuntu@<EC2_SERVER_IP> 'sudo cp /var/lib/rancher/k3s/server/db/state.db ~/k3s-backup.db && sudo chown ubuntu:ubuntu ~/k3s-backup.db'
scp -i ~/.ssh/your-aws-key.pem ubuntu@<EC2_SERVER_IP>:~/k3s-backup.db ./
```

## Conclusion

You now have a fully functional K3s Kubernetes cluster running on AWS EC2 instances, configured with Ansible. This setup provides a lightweight, production-ready Kubernetes environment suitable for various workloads.

For more information on K3s, visit the [official K3s documentation](https://docs.k3s.io/).
