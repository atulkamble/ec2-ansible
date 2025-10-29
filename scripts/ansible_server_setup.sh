#!/bin/bash

# Update system
sudo dnf update -y

# Install Ansible
sudo dnf install -y ansible-core

# Create ansible directory structure
sudo mkdir -p /etc/ansible/inventory
sudo mkdir -p /etc/ansible/playbooks

# Create ansible.cfg
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

# Create inventory file with host IPs
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

# Setup SSH key for ansible
cat <<'EOF' | sudo tee /home/ec2-user/.ssh/ansible.pem
${private_key}
EOF

sudo chmod 600 /home/ec2-user/.ssh/ansible.pem
sudo chown ec2-user:ec2-user /home/ec2-user/.ssh/ansible.pem

# Create a sample ping playbook
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

# Wait for hosts to be fully up
sleep 30

# Test connectivity (run as ec2-user)
echo "Testing Ansible connectivity..." | sudo tee -a /var/log/ansible-setup.log
sudo -u ec2-user ansible ansible_hosts -m ping >> /var/log/ansible-setup.log 2>&1 || true

echo "Ansible server setup complete!" | sudo tee -a /var/log/ansible-setup.log
