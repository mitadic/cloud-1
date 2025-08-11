# Playbook Docs

This file documents the usage of Ansible playbooks for deploying the instances of the WordPress application on AWS EC2 instances with persistent storage and containerized architecture.

## Architecture Recap

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AWS Account   │    │   EC2 Instance  │    │   Application   │
│                 │    │                 │    │                 │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │Security   │  │    │  │Docker     │  │    │  │WordPress  │  │
│  │Groups     │  │────┤  │Network    │  │    │  │+ MariaDB  │  │
│  └───────────┘  │    │  └───────────┘  │    │  │+ Nginx    │  │
│                 │    │                 │    │  └───────────┘  │
│  ┌───────────┐  │    │  ┌───────────┐  │    |                 |
│  │EBS Volume │  │    │  │Persistent │  │    │                 │
│  │(2GB)      │  │────┤  │Storage    │  │    │                 │
│  └───────────┘  │    │  └───────────┘  │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Resources Created:**
- 3x EC2 t2.micro instances (Ubuntu LTS)
- 3x EBS volumes (2GB each)
- Security group with HTTP/HTTPS/SSH access
- Dynamic inventory for instance management

## Playbook Reference

### `AWS_create_ec2.yaml`
**Purpose:** Creates EC2 instances and attaches EBS volumes for persistent storage.

**Key Variables:**
- `region`: AWS region (default: `eu-central-1`)
- `instance_type`: EC2 instance type (default: `t2.micro`)
- `ami_id`: Ubuntu LTS AMI ID (default: `ami-02003f9f0fde924ea`)
- `key_name`: SSH key pair name (default: `cloud-1-jubernar`)
- `volume_size`: EBS volume size in GB (default: `2`)
- `count`: Number of instances to create (default: `3`)

**Usage:**
```bash
ansible-playbook playbooks/AWS_create_ec2.yaml
```

**Dependencies:** Requires `AWS_security_group.yaml` to be run first.

### `AWS_security_group.yaml`
**Purpose:** Creates and configures security groups for web applications.

**Usage:**
```bash
ansible-playbook playbooks/AWS_security_group.yaml
```

**Dependencies:** None (run first).

### `AWS_mount_ebs.yaml`
**Purpose:** Formats and mounts EBS volumes on EC2 instances.

**Usage:**
```bash
ansible-playbook -i inventory.yaml playbooks/AWS_mount_ebs.yaml
```

**Dependencies:** Requires `AWS_create_ec2.yaml` to generate inventory.

### `setup.yaml`
**Purpose:** Configures EC2 instances with Docker, Docker Compose, and system dependencies.

**Usage:**
```bash
ansible-playbook -i inventory.yaml playbooks/setup.yaml
```

**Dependencies:** Requires mounted EBS volumes.

### `deploy.yaml`
**Purpose:** Deploys WordPress application stack using Docker Compose.

**Usage:**
```bash
ansible-playbook -i inventory.yaml playbooks/deploy.yaml
```

**Dependencies:** Requires completed setup phase.

### `clean.yaml`
**Purpose:** Removes all AWS resources created by the deployment.

**Usage:**
```bash
ansible-playbook playbooks/clean.yaml
```

**Dependencies:** None (can be run independently).

## Common Pitfalls & Troubleshooting

### 🔐 Security & Credentials
- **Credentials management tip**: Use environment variables or AWS credential profiles.
- **SSH key permissions**: Ensure private key has correct permissions (`chmod 600`).
- **Security group dependencies**: Always run `AWS_security_group.yaml` before `AWS_create_ec2.yaml`.

### 💾 Storage & Mounting
- **EBS device naming**: Device names (`/dev/sdf`) may vary by instance type. Monitor AWS console for actual device assignments.
- **Volume attachment timing**: Allow time for EBS volumes to attach before mounting operations.
- **Filesystem formatting**: EBS volumes need formatting on first use - this is handled automatically.

### 🌐 Network & Connectivity
- **SSH connectivity**: Verify security group allows SSH (port 22) from your IP.
- **Public IP assignment**: Ensure instances have public IPs for external access.
- **DNS resolution**: Use public IP addresses initially; DNS setup is not automated.

### 🐳 Container Deployment
- **Docker service startup**: Allow time for Docker daemon to start after installation.
- **Container registry access**: Ensure instances can pull Docker images from registries.
- **Port conflicts**: Verify no conflicts with default ports (80, 443, 3306, 8080).

### 📊 Inventory Management
- **Dynamic inventory**: The `inventory.yaml` file is auto-generated. Don't edit manually.
- **Instance state**: Verify instances are in 'running' state before proceeding with setup.
- **SSH host verification**: Use `StrictHostKeyChecking=no` for automated deployments.

## Workflow Guide / Dissecting what the Makefile is doing

### Complete Deployment Process
1. **Infrastructure Setup**
   ```bash
   ansible-playbook playbooks/AWS_security_group.yaml
   ansible-playbook playbooks/AWS_create_ec2.yaml
   ansible-playbook -i inventory.yaml playbooks/AWS_mount_ebs.yaml
   ```

2. **Server Configuration**
   ```bash
   ansible-playbook -i inventory.yaml playbooks/setup.yaml
   ```

3. **Application Deployment**
   ```bash
   ansible-playbook -i inventory.yaml playbooks/deploy.yaml
   ```

4. **Access Your Application**
   - Check `inventory.yaml` for instance IPs
   - Access via `http://<instance-ip>:8080`

### Update/Redeploy Application
```bash
ansible-playbook -i inventory.yaml playbooks/deploy.yaml
```

### Scaling Operations
To change the number of instances:
1. Edit `count` variable in `AWS_create_ec2.yaml`
2. Re-run the complete deployment process

### Cleanup
```bash
ansible-playbook playbooks/clean.yaml
```

## Configuration Files

### `main.yaml`
The main orchestration playbook that runs all deployment phases in sequence.

### `inventory.yaml`
Auto-generated inventory file containing EC2 instance details. Format:
```yaml
my_ec2_hosts:
  hosts:
    instance1:
      ansible_host: <public_ip>
    instance2:
      ansible_host: <public_ip>
    instance3:
      ansible_host: <public_ip>
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ./cloud-1-jubernar.pem
    ansible_ssh_common_args: "-o StrictHostKeyChecking=no"
```

## Support

For issues related to AWS resources, check the AWS Management Console for detailed error messages. For Ansible-specific issues, run playbooks with `-vvv` for verbose output.

**Common debugging commands:**
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Test SSH connectivity
ssh -i ./cloud-1-jubernar.pem ubuntu@<instance-ip>

# Check Ansible inventory
ansible-inventory -i inventory.yaml --list

# Run with verbose output
ansible-playbook -i inventory.yaml playbooks/deploy.yaml -vvv
```
