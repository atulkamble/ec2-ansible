variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "public_key_path" {
  description = "Path to the public key file for SSH access"
  type        = string
  default     = "~/.ssh/ansible.pub"
}

variable "private_key_path" {
  description = "Path to the private key file for Ansible connections"
  type        = string
  default     = "~/.ssh/ansible.pem"
}
