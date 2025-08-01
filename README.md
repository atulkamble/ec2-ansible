# Ansible Setup on AWS EC2 Instances

## Overview

This guide sets up an Ansible control node on an EC2 instance and connects to two other managed EC2 hosts for automation.

---

## 1. EC2 Instance Setup

### Launch 3 EC2 Instances

* **AMI**: Amazon Linux 2
* **Network**: Same VPC and Subnet
* **Instance Types**:

  * **1 Ansible Control Node**: `t3.medium` (Start with `t3.micro` and upgrade to `t3.medium`)
  * **2 Managed Hosts**: `t3.micro` each

### SSH Key Pair

* Create/use a key pair named `ansible.pem`

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

