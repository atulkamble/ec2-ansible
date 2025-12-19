# AWS Ansible Infrastructure with Terraform

This repository contains Terraform configuration to automatically provision an Ansible control node (server) with 2 managed host machines on AWS EC2.

## Architecture

- **Ansible Server**: t3.medium instance running Amazon Linux 2023
- **Host Machines**: 2 x t3.micro instances running Amazon Linux 2023
- **Networking**: Custom VPC with public subnet and Internet Gateway
- **Security**: Separate security groups for server and hosts
- **Authentication**: SSH key-based authentication using `ansible.pem`

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Terraform** installed (v1.0+)
4. **SSH Key Pair** generated

## Quick Start

### Method 1: Automated Setup (Recommended)

Run the automated setup script that handles everything:

```bash
chmod +x setup.sh
./setup.sh
```

This script will:
1. ✅ Check for SSH key pair and generate if needed
2. ✅ Create `terraform.tfvars` configuration
3. ✅ Check if key exists in AWS
4. ✅ Initialize Terraform
5. ✅ Validate configuration
6. ✅ Show deployment plan
7. ✅ Optionally deploy the infrastructure

### Method 2: Manual Setup

#### 1. Generate SSH Key Pair (Automatic)

Run the key generation script:
```bash
chmod +x generate_key.sh
./generate_key.sh
```

This will:
- Check if `~/.ssh/ansible.pem` already exists
- Generate new key pair if not present
- Set proper permissions automatically

Or manually generate:
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible.pem -N "" -C "ansible-key"
chmod 600 ~/.ssh/ansible.pem
chmod 644 ~/.ssh/ansible.pub
```

#### 2. Check/Import Key in AWS (Optional)

Check if the key already exists in AWS:
```bash
chmod +x check_and_import_key.sh
./check_and_import_key.sh us-east-1
```

If you have an existing key pair in AWS, import it to Terraform state:
```bash
terraform import aws_key_pair.ansible_key ansible
```

#### 3. Configure Variables

Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your settings. You have three options for key pair configuration:

**Option 1: Create a new key pair (default)**
```hcl
aws_region            = "us-east-1"
public_key_path       = "~/.ssh/ansible.pub"
private_key_path      = "~/.ssh/ansible.pem"
key_pair_name         = "ansible"
create_key_pair       = true
use_existing_key_pair = false
```

**Option 2: Use an existing AWS key pair**
```hcl
aws_region            = "us-east-1"
private_key_path      = "~/.ssh/my-existing-key.pem"
key_pair_name         = "my-existing-key"  # Name of your existing AWS key pair
create_key_pair       = false
use_existing_key_pair = true
# public_key_path not needed when using existing key pair
```

**Option 3: Let Terraform manage existing key pair**
If you have a local key pair but want to import it to AWS:
```hcl
aws_region            = "us-east-1"
public_key_path       = "~/.ssh/ansible.pub"
private_key_path      = "~/.ssh/ansible.pem"
key_pair_name         = "ansible"
create_key_pair       = true
use_existing_key_pair = false
```

#### 4. Initialize Terraform

```bash
terraform init
```

#### 5. Review the Plan

```bash
terraform plan
```

#### 6. Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted to create the infrastructure.

#### 7. Get Connection Details

After successful deployment:
```bash
terraform output
```

## Infrastructure Components

### VPC Configuration
- **VPC CIDR**: 10.0.0.0/16
- **Public Subnet**: 10.0.1.0/24
- **Internet Gateway**: For public internet access
- **Route Table**: Routes traffic to IGW

### EC2 Instances

#### Ansible Server (t3.medium)
- Ansible Core installed
- Configured with `ansible.cfg`
- Inventory file at `/etc/ansible/inventory/hosts`
- Playbooks directory at `/etc/ansible/playbooks`
- Private key configured for host connections

#### Host Machines (2 x t3.micro)
- Amazon Linux 2023
- SSH access configured
- Managed by Ansible server

### Security Groups

#### Ansible Server Security Group
- **Inbound**: SSH (22) from anywhere
- **Outbound**: All traffic

#### Host Machines Security Group
- **Inbound**: SSH (22) from anywhere and from Ansible server
- **Outbound**: All traffic

## Ansible Configuration

### Configuration File (`/etc/ansible/ansible.cfg`)

```ini
[defaults]
inventory = /etc/ansible/inventory/hosts
remote_user = ec2-user
private_key_file = /home/ec2-user/.ssh/ansible.pem
host_key_checking = False
```

### Inventory File (`/etc/ansible/inventory/hosts`)

```ini
[ansible_hosts]
host1 ansible_host=<HOST1_PRIVATE_IP>
host2 ansible_host=<HOST2_PRIVATE_IP>

[ansible_hosts:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=/home/ec2-user/.ssh/ansible.pem
```

## Sample Playbooks

Three sample playbooks are created automatically in `/etc/ansible/playbooks/`:

### 1. ping.yml
Tests connectivity and displays host information.

### 2. update_hosts.yml
Updates all packages on managed hosts.

### 3. install_packages.yml
Installs common development tools.

## Usage

### Connect to Ansible Server

```bash
ssh -i ~/.ssh/ansible.pem ec2-user@<ANSIBLE_SERVER_PUBLIC_IP>
```

### Test Ansible Connectivity

```bash
ansible ansible_hosts -m ping
```

### Run Ad-hoc Commands

```bash
# Check uptime
ansible ansible_hosts -a "uptime"

# Check disk space
ansible ansible_hosts -a "df -h"

# Check memory
ansible ansible_hosts -a "free -h"
```

### Run Playbooks

```bash
# Test connectivity
ansible-playbook /etc/ansible/playbooks/ping.yml

# Update all hosts
ansible-playbook /etc/ansible/playbooks/update_hosts.yml

# Install packages
ansible-playbook /etc/ansible/playbooks/install_packages.yml
```

### View Inventory

```bash
ansible-inventory --list
ansible-inventory --graph
```

## Outputs

The following outputs are available after deployment:

- `ansible_server_public_ip`: Public IP of Ansible server
- `ansible_server_private_ip`: Private IP of Ansible server
- `ansible_host1_public_ip`: Public IP of Host 1
- `ansible_host1_private_ip`: Private IP of Host 1
- `ansible_host2_public_ip`: Public IP of Host 2
- `ansible_host2_private_ip`: Private IP of Host 2
- `ssh_command_ansible_server`: SSH command for Ansible server
- `ssh_command_host1`: SSH command for Host 1
- `ssh_command_host2`: SSH command for Host 2

## File Structure

```
.
├── main.tf                          # Main Terraform configuration
├── variables.tf                     # Variable definitions
├── outputs.tf                       # Output definitions
├── terraform.tfvars.example         # Example variables file
├── setup.sh                         # Automated complete setup script
├── generate_key.sh                  # SSH key generation script
├── check_and_import_key.sh         # AWS key pair check/import script
├── scripts/
│   └── ansible_server_setup.sh     # Ansible server setup script
├── .gitignore                       # Git ignore file
└── README.md                        # This file
```

## Key Management

### Automatic Key Generation

The `generate_key.sh` script automatically:
- ✅ Checks if `ansible.pem` already exists
- ✅ Generates new key pair if not present
- ✅ Sets proper permissions (600 for private, 644 for public)
- ✅ Displays key fingerprint

### Using Existing Keys

If you already have `ansible.pem`:
1. Place it in `~/.ssh/ansible.pem`
2. Ensure the public key is at `~/.ssh/ansible.pub`
3. Run `./generate_key.sh` to verify and set permissions
4. Run `./check_and_import_key.sh` to check AWS status

### Importing Existing AWS Key Pair

If the key pair already exists in your AWS account:
```bash
# Import to Terraform state
terraform import aws_key_pair.ansible_key ansible

# Then run terraform plan to verify
terraform plan
```

## Troubleshooting

### Check Ansible Server Setup Logs

```bash
ssh -i ~/.ssh/ansible.pem ec2-user@<ANSIBLE_SERVER_IP>
sudo cat /var/log/ansible-setup.log
```

### Verify Ansible Installation

```bash
ansible --version
```

### Test Host Connectivity Manually

```bash
ssh -i ~/.ssh/ansible.pem ec2-user@<HOST_PRIVATE_IP>
```

### Common Issues

1. **Permission denied (publickey)**
   - Run `./generate_key.sh` to ensure correct permissions
   - Verify: `ls -la ~/.ssh/ansible.pem` should show `-rw-------`

2. **Key pair already exists in AWS**
   - Import existing key: `terraform import aws_key_pair.ansible_key ansible`
   - Or delete from AWS and let Terraform create new one

3. **Hosts unreachable**
   - Check security group rules
   - Verify hosts are running: `terraform show`
   - Wait 2-3 minutes for user_data script to complete

4. **Ansible command not found**
   - Wait for user_data script to complete (check `/var/log/ansible-setup.log`)
   - User_data runs on first boot and may take 2-5 minutes

5. **terraform.tfvars not found**
   - Run `./setup.sh` or copy from `terraform.tfvars.example`

## Cleanup

To destroy all created resources:

```bash
terraform destroy
```

Type `yes` when prompted.

## Cost Estimate

- t3.medium: ~$0.0416/hour
- 2 x t3.micro: ~$0.0104/hour each
- **Total**: ~$0.0624/hour (~$45/month if running 24/7)

## Security Best Practices

1. **Restrict SSH Access**: Modify security group to allow SSH only from your IP
2. **Use IAM Roles**: Consider using IAM roles instead of access keys
3. **Enable CloudWatch**: Monitor instance metrics and logs
4. **Regular Updates**: Keep systems updated with security patches
5. **Key Management**: Store private keys securely, never commit to git

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

Created for AWS Ansible automation and infrastructure management.

## References

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Amazon Linux 2023 User Guide](https://docs.aws.amazon.com/linux/al2023/ug/)

---

## 1. EC2 Instance Setup

### Launch 3 EC2 Instances

* **AMI**: Amazon Linux 2023
* **Network**: Same VPC and Subnet
* **Instance Types**:

  * **1 Ansible Control Node**: `t3.medium` (Start with `t3.micro` and upgrade to `t3.medium`)
  * **2 Managed Hosts**: `t3.micro` each

### SSH Key Pair

* use a key pair named `ansible.pem`

---

## 2. Setup on the Control Node (Ansible Server)

### Initial Configuration

SSH into the control node and run:

```bash
sudo yum update -y
sudo yum install python3-pip tree -y

python3 --version
pip3 --version

sudo pip3 install ansible
# Optionally check for Ansible via yum
sudo yum search ansible
sudo yum install ansible.noarch

ansible --version
```

---

## 3. Ansible Project Structure

Directory layout on the control node:

```bash
.
├── ansible.cfg
├── aws
│   └── ansible.pem          # Your private key for SSH
├── inventory
│   └── hosts                # Inventory file with EC2 public IPs
├── playbooks                # Directory for playbooks
└── roles                    # Directory for roles
```

---

## 4. `ansible.cfg`

Create a file named `ansible.cfg` in the root of your project:

```ini
[defaults]
inventory = ./inventory
remote_user = ec2-user
private_key_file = aws/ansible.pem
host_key_checking = False
retry_files_enabled = False

[privilege_escalation]
become = true
become_method = sudo
become_user = root
become_ask_pass = false
```

---

## 5. Inventory File

Create `inventory/hosts` and add your EC2 **public IP addresses**:

```ini
[all]
174.129.61.157
52.90.194.255
```

Or group them optionally:

```ini
[webservers]
174.129.61.157
52.90.194.255
```

---

## 6. Testing Connection

Use Ansible’s `ping` module to test connectivity:

```bash
sudo ansible -m ping all
```

Expected output:

```text
174.129.61.157 | SUCCESS => {...}
52.90.194.255 | SUCCESS => {...}
```

---

## Notes

* Make sure the **security group** attached to all instances allows inbound **SSH (port 22)** from your IP or VPC.
* Ensure the `ansible.pem` file has proper permissions:

  ```bash
  chmod 400 aws/ansible.pem
  ```

