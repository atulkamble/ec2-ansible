#!/bin/bash

# Redirect all output to log file
exec > >(tee -a /var/log/ansible-setup.log)
exec 2>&1

echo "========================================"
echo "Starting Ansible Server Setup"
echo "Date: $(date)"
echo "========================================"

# Update system
echo "Step 1: Updating system packages..."
sudo yum update -y

# Enable EPEL repository for Ansible (if needed)
echo "Step 2: Enabling EPEL repository..."
sudo amazon-linux-extras install epel -y 2>/dev/null || true

# Install Ansible with retry logic
echo "Step 3: Installing Ansible..."
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Installation attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES..."
    
    # Try installing ansible.noarch
    if sudo yum install -y ansible.noarch; then
        echo "✓ Ansible installed successfully"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "Installation failed. Retrying in 5 seconds..."
            sleep 5
        else
            echo "✗ Failed to install Ansible after $MAX_RETRIES attempts"
            echo "Trying alternative installation method..."
            sudo yum install -y ansible || sudo amazon-linux-extras install ansible2 -y
        fi
    fi
done

# Verify Ansible installation
echo "Step 4: Verifying Ansible installation..."
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n 1)
    echo "✓ Ansible installed: $ANSIBLE_VERSION"
else
    echo "✗ ERROR: Ansible installation failed!"
    exit 1
fi

# Install Python 3 and pip
echo "Step 5: Installing Python 3 and pip..."
sudo yum install -y python3 python3-pip

# Verify Python installation
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✓ Python installed: $PYTHON_VERSION"
else
    echo "✗ WARNING: Python3 installation failed"
fi

# Verify pip installation
if command -v pip3 &> /dev/null; then
    PIP_VERSION=$(pip3 --version)
    echo "✓ pip installed: $PIP_VERSION"
else
    echo "✗ WARNING: pip3 installation failed"
fi

# Upgrade pip to latest version
echo "Upgrading pip to latest version..."
sudo pip3 install --upgrade pip 2>/dev/null || true

# Install useful Python packages for Ansible
echo "Installing additional Python packages..."
sudo pip3 install --upgrade setuptools wheel 2>/dev/null || true
sudo pip3 install boto3 botocore 2>/dev/null || true
echo "✓ Python environment configured"

# Create ansible directory structure
echo "Step 6: Creating Ansible directory structure..."
sudo mkdir -p /etc/ansible/inventory
sudo mkdir -p /etc/ansible/playbooks
echo "✓ Directories created"

# Create ansible.cfg
echo "Step 7: Creating Ansible configuration file..."
cat <<EOF | sudo tee /etc/ansible/ansible.cfg
[defaults]
inventory = /etc/ansible/inventory/hosts
remote_user = ec2-user
private_key_file = /home/ec2-user/.ssh/ansible.pem
host_key_checking = False
timeout = 30
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
pipelining = True
EOF
echo "✓ Ansible configuration created"

# Create inventory file with host IPs
echo "Step 8: Creating inventory file with host IPs..."
cat <<EOF | sudo tee /etc/ansible/inventory/hosts
[ansible_hosts]
host1 ansible_host=${host1_ip}
host2 ansible_host=${host2_ip}

[ansible_hosts:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=/home/ec2-user/.ssh/ansible.pem
ansible_python_interpreter=/usr/bin/python3

[all:vars]
ansible_connection=ssh
EOF
echo "✓ Inventory file created with host IPs"

# Setup SSH key for ansible
echo "Step 9: Setting up SSH key for Ansible..."
cat <<'EOF' | sudo tee /home/ec2-user/.ssh/ansible.pem
${private_key}
EOF

sudo chmod 600 /home/ec2-user/.ssh/ansible.pem
sudo chown ec2-user:ec2-user /home/ec2-user/.ssh/ansible.pem
echo "✓ SSH key configured"

# Create a sample ping playbook
echo "Step 10: Creating sample playbooks..."
cat <<'EOF' | sudo tee /etc/ansible/playbooks/ping.yml
---
- name: Test connectivity to all hosts
  hosts: ansible_hosts
  gather_facts: yes
  tasks:
    - name: Ping test
      ping:

    - name: Display hostname
      debug:
        msg: "Hostname: {{ ansible_hostname }}"

    - name: Display IP address
      debug:
        msg: "IP Address: {{ ansible_default_ipv4.address }}"
EOF

# Create a sample update playbook
cat <<'EOF' | sudo tee /etc/ansible/playbooks/update_hosts.yml
---
- name: Update all managed hosts
  hosts: ansible_hosts
  become: yes
  tasks:
    - name: Update all packages
      dnf:
        name: "*"
        state: latest
        update_cache: yes

    - name: Check if reboot is required
      stat:
        path: /var/run/reboot-required
      register: reboot_required

    - name: Display reboot status
      debug:
        msg: "Reboot required: {{ reboot_required.stat.exists }}"
EOF

# Create a sample install packages playbook
cat <<'EOF' | sudo tee /etc/ansible/playbooks/install_packages.yml
---
- name: Install common packages on all hosts
  hosts: ansible_hosts
  become: yes
  tasks:
    - name: Install common tools
      dnf:
        name:
          - git
          - wget
          - curl
          - vim
          - htop
        state: present
        update_cache: yes

    - name: Verify installations
      command: "{{ item }} --version"
      loop:
        - git
        - wget
        - curl
        - vim
      register: version_check
      changed_when: false

    - name: Display versions
      debug:
        msg: "{{ item.stdout_lines }}"
      loop: "{{ version_check.results }}"
EOF

# Set proper permissions
sudo chown -R ec2-user:ec2-user /etc/ansible/playbooks
sudo chmod 755 /etc/ansible/playbooks
sudo chmod 644 /etc/ansible/playbooks/*.yml
sudo chmod 644 /etc/ansible/ansible.cfg
sudo chmod 644 /etc/ansible/inventory/hosts

# Create a README in the playbooks directory
cat <<'EOF' | sudo tee /etc/ansible/playbooks/README.md
# Ansible Playbooks Directory

This directory contains Ansible playbooks for managing the infrastructure.

## Available Playbooks

### 1. ping.yml
Tests connectivity to all managed hosts and displays basic information.

**Usage:**
```bash
ansible-playbook /etc/ansible/playbooks/ping.yml
```

### 2. update_hosts.yml
Updates all packages on managed hosts to the latest version.

**Usage:**
```bash
ansible-playbook /etc/ansible/playbooks/update_hosts.yml
```

### 3. install_packages.yml
Installs common development tools on all managed hosts.

**Usage:**
```bash
ansible-playbook /etc/ansible/playbooks/install_packages.yml
```

## Testing Ansible Connectivity

Test connection to all hosts:
```bash
ansible ansible_hosts -m ping
```

Run ad-hoc commands:
```bash
ansible ansible_hosts -a "uptime"
ansible ansible_hosts -a "df -h"
```

## Inventory

The inventory file is located at: `/etc/ansible/inventory/hosts`

To view inventory:
```bash
ansible-inventory --list
```
EOF

sudo chown ec2-user:ec2-user /etc/ansible/playbooks/README.md
echo "✓ Sample playbooks and documentation created"

# Set proper permissions
echo "Step 11: Setting proper permissions..."
sudo chown -R ec2-user:ec2-user /etc/ansible/playbooks
sudo chmod 755 /etc/ansible/playbooks
sudo chmod 644 /etc/ansible/playbooks/*.yml
sudo chmod 644 /etc/ansible/ansible.cfg
sudo chmod 644 /etc/ansible/inventory/hosts
echo "✓ Permissions configured"

# Wait for hosts to be fully up
echo "Step 12: Waiting for host machines to be ready..."
sleep 30
echo "✓ Wait complete"

# Test connectivity (run as ec2-user)
echo "Step 13: Testing Ansible connectivity to managed hosts..."
echo "Testing connectivity..." | sudo tee -a /var/log/ansible-setup.log
sudo -u ec2-user ansible ansible_hosts -m ping >> /var/log/ansible-setup.log 2>&1 || echo "Note: Connectivity test may fail initially. Hosts might still be booting."

# Final verification
echo ""
echo "========================================"
echo "Ansible Server Setup Complete!"
echo "========================================"
echo ""
echo "Installation Summary:"
echo "  - Ansible Version: $(ansible --version | head -n 1)"
echo "  - Python Version: $(python3 --version)"
echo "  - pip Version: $(pip3 --version | cut -d' ' -f1-2)"
echo "  - Config File: /etc/ansible/ansible.cfg"
echo "  - Inventory: /etc/ansible/inventory/hosts"
echo "  - Playbooks: /etc/ansible/playbooks/"
echo ""
echo "To test Ansible manually:"
echo "  ansible ansible_hosts -m ping"
echo "  ansible-playbook /etc/ansible/playbooks/ping.yml"
echo ""
echo "Full setup log: /var/log/ansible-setup.log"
echo "========================================"
echo ""

# Create a status file to indicate setup completion
echo "Setup completed at $(date)" | sudo tee /var/log/ansible-setup-complete.txt
sudo chmod 644 /var/log/ansible-setup-complete.txt
