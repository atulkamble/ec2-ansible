# Quick Reference Guide

## 🚀 Quick Start Commands

```bash
# Complete automated setup
./setup.sh

# Or step-by-step:
./generate_key.sh           # Generate SSH keys
terraform init              # Initialize Terraform
terraform plan              # Preview changes
terraform apply             # Deploy infrastructure
```

## 📋 What Gets Created

| Resource | Type | Configuration |
|----------|------|---------------|
| Ansible Server | EC2 t3.medium | Amazon Linux 2023 + Ansible installed |
| Host Machine 1 | EC2 t3.micro | Amazon Linux 2023 |
| Host Machine 2 | EC2 t3.micro | Amazon Linux 2023 |
| VPC | Network | 10.0.0.0/16 |
| Subnet | Network | 10.0.1.0/24 (public) |
| Security Groups | Firewall | SSH access configured |
| SSH Key Pair | Auth | ansible.pem/ansible.pub |

## 🔧 Ansible Configuration

### Server Side (Auto-configured)
```
/etc/ansible/
├── ansible.cfg              # Main config
├── inventory/
│   └── hosts               # Host IPs (auto-populated)
└── playbooks/
    ├── ping.yml            # Test connectivity
    ├── update_hosts.yml    # Update packages
    └── install_packages.yml # Install tools
```

### Key Settings
- **Inventory:** `/etc/ansible/inventory/hosts`
- **User:** `ec2-user`
- **Private Key:** `/home/ec2-user/.ssh/ansible.pem`
- **Host Check:** Disabled

## 💻 Usage After Deployment

### Get Connection Details
```bash
terraform output
```

### Connect to Ansible Server
```bash
ssh -i ~/.ssh/ansible.pem ec2-user@<ANSIBLE_SERVER_IP>
```

### Test Ansible Connectivity
```bash
# Ping all hosts
ansible ansible_hosts -m ping

# Ad-hoc commands
ansible ansible_hosts -a "uptime"
ansible ansible_hosts -a "df -h"
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

## 🛠️ Management Commands

### Terraform
```bash
terraform plan              # Preview changes
terraform apply             # Apply changes
terraform destroy           # Destroy all resources
terraform output            # Show outputs
terraform show              # Show current state
```

### SSH Keys
```bash
./generate_key.sh           # Generate/verify keys
./check_and_import_key.sh   # Check AWS key status
```

## 📊 Outputs Available

```bash
ansible_server_public_ip    # Public IP of Ansible server
ansible_server_private_ip   # Private IP of Ansible server
ansible_host1_public_ip     # Public IP of Host 1
ansible_host1_private_ip    # Private IP of Host 1
ansible_host2_public_ip     # Public IP of Host 2
ansible_host2_private_ip    # Private IP of Host 2
ssh_command_ansible_server  # Ready-to-use SSH command
ssh_command_host1           # SSH command for Host 1
ssh_command_host2           # SSH command for Host 2
```

## 🔍 Troubleshooting

### Check Setup Logs
```bash
ssh -i ~/.ssh/ansible.pem ec2-user@<SERVER_IP>
sudo cat /var/log/ansible-setup.log
```

### Verify Ansible Installation
```bash
ansible --version
ansible-config dump
```

### Test Individual Host
```bash
ansible host1 -m ping
ssh -i ~/.ssh/ansible.pem ec2-user@<HOST1_PRIVATE_IP>
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Permission denied | Run `./generate_key.sh` to fix permissions |
| Hosts unreachable | Wait 2-3 min for user_data to complete |
| Key exists in AWS | Run `terraform import aws_key_pair.ansible_key ansible` |
| Terraform errors | Run `terraform init` again |

## 💰 Cost Management

### Estimated Costs
- **Hourly:** ~$0.06
- **Daily:** ~$1.50
- **Monthly:** ~$45 (if running 24/7)

### Cleanup
```bash
terraform destroy           # Remove all resources
# Type 'yes' when prompted
```

## 🔒 Security Checklist

- [x] Private key has 600 permissions
- [x] Keys not committed to git (.gitignore)
- [x] Security groups configured
- [x] Host key checking disabled for automation
- [ ] Consider restricting SSH to your IP only
- [ ] Enable CloudWatch monitoring (optional)
- [ ] Regular system updates via playbooks

## 📁 File Reference

| File | Purpose |
|------|---------|
| `main.tf` | Infrastructure definition |
| `variables.tf` | Input variables |
| `outputs.tf` | Output values |
| `terraform.tfvars` | Variable values |
| `setup.sh` | Complete automation |
| `generate_key.sh` | SSH key management |
| `check_and_import_key.sh` | AWS key validation |
| `scripts/ansible_server_setup.sh` | Server bootstrap |

## 🎯 Next Steps

1. ✅ Deploy infrastructure: `terraform apply`
2. ✅ Get server IP: `terraform output ansible_server_public_ip`
3. ✅ SSH to server: Use output command
4. ✅ Test Ansible: `ansible ansible_hosts -m ping`
5. ✅ Run playbook: `ansible-playbook /etc/ansible/playbooks/ping.yml`
6. ✅ Create custom playbooks in `/etc/ansible/playbooks/`
7. ✅ Automate your infrastructure!

## 📚 Documentation

- Full README: `README.md`
- Test Results: `TEST_RESULTS.md`
- This Guide: `QUICK_REFERENCE.md`

---

**Ready to deploy?** Run `./setup.sh` or `terraform apply`
