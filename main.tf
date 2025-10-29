terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "ansible_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ansible-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "ansible_igw" {
  vpc_id = aws_vpc.ansible_vpc.id

  tags = {
    Name = "ansible-igw"
  }
}

# Create Public Subnet
resource "aws_subnet" "ansible_public_subnet" {
  vpc_id                  = aws_vpc.ansible_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "ansible-public-subnet"
  }
}

# Create Route Table
resource "aws_route_table" "ansible_public_rt" {
  vpc_id = aws_vpc.ansible_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ansible_igw.id
  }

  tags = {
    Name = "ansible-public-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "ansible_public_rta" {
  subnet_id      = aws_subnet.ansible_public_subnet.id
  route_table_id = aws_route_table.ansible_public_rt.id
}

# Security Group for Ansible Server
resource "aws_security_group" "ansible_server_sg" {
  name        = "ansible-server-sg"
  description = "Security group for Ansible control node"
  vpc_id      = aws_vpc.ansible_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ansible-server-sg"
  }
}

# Security Group for Host Machines
resource "aws_security_group" "ansible_hosts_sg" {
  name        = "ansible-hosts-sg"
  description = "Security group for Ansible managed hosts"
  vpc_id      = aws_vpc.ansible_vpc.id

  # SSH access from anywhere (you may want to restrict this)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from Ansible server
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ansible_server_sg.id]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ansible-hosts-sg"
  }
}

# Create Key Pair or import existing
resource "aws_key_pair" "ansible_key" {
  key_name   = "ansible"
  public_key = file(var.public_key_path)

  tags = {
    Name = "ansible-keypair"
  }

  lifecycle {
    ignore_changes = [public_key]
  }
}

# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Ansible Server (Control Node)
resource "aws_instance" "ansible_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.ansible_key.key_name
  vpc_security_group_ids = [aws_security_group.ansible_server_sg.id]
  subnet_id              = aws_subnet.ansible_public_subnet.id

  user_data = templatefile("${path.module}/scripts/ansible_server_setup.sh", {
    host1_ip    = aws_instance.ansible_host1.private_ip
    host2_ip    = aws_instance.ansible_host2.private_ip
    private_key = file(var.private_key_path)
  })

  tags = {
    Name = "ansible-server"
    Role = "control-node"
  }

  depends_on = [
    aws_instance.ansible_host1,
    aws_instance.ansible_host2
  ]
}

# Ansible Host 1
resource "aws_instance" "ansible_host1" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ansible_key.key_name
  vpc_security_group_ids = [aws_security_group.ansible_hosts_sg.id]
  subnet_id              = aws_subnet.ansible_public_subnet.id

  tags = {
    Name = "ansible-host-1"
    Role = "managed-node"
  }
}

# Ansible Host 2
resource "aws_instance" "ansible_host2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ansible_key.key_name
  vpc_security_group_ids = [aws_security_group.ansible_hosts_sg.id]
  subnet_id              = aws_subnet.ansible_public_subnet.id

  tags = {
    Name = "ansible-host-2"
    Role = "managed-node"
  }
}
