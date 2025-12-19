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

variable "key_pair_name" {
  description = "Name of the AWS key pair to use"
  type        = string
  default     = "ansible"
}

variable "create_key_pair" {
  description = "Whether to create a new key pair (true) or use existing one (false)"
  type        = bool
  default     = true
}

variable "use_existing_key_pair" {
  description = "Whether to use an existing key pair instead of creating a new one"
  type        = bool
  default     = false
}
