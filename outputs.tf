output "ansible_server_public_ip" {
  description = "Public IP address of the Ansible server"
  value       = aws_instance.ansible_server.public_ip
}

output "ansible_server_private_ip" {
  description = "Private IP address of the Ansible server"
  value       = aws_instance.ansible_server.private_ip
}

output "ansible_host1_public_ip" {
  description = "Public IP address of Ansible Host 1"
  value       = aws_instance.ansible_host1.public_ip
}

output "ansible_host1_private_ip" {
  description = "Private IP address of Ansible Host 1"
  value       = aws_instance.ansible_host1.private_ip
}

output "ansible_host2_public_ip" {
  description = "Public IP address of Ansible Host 2"
  value       = aws_instance.ansible_host2.public_ip
}

output "ansible_host2_private_ip" {
  description = "Private IP address of Ansible Host 2"
  value       = aws_instance.ansible_host2.private_ip
}

output "ssh_command_ansible_server" {
  description = "SSH command to connect to Ansible server"
  value       = "ssh -i ~/.ssh/ansible.pem ec2-user@${aws_instance.ansible_server.public_ip}"
}

output "ssh_command_host1" {
  description = "SSH command to connect to Host 1"
  value       = "ssh -i ~/.ssh/ansible.pem ec2-user@${aws_instance.ansible_host1.public_ip}"
}

output "ssh_command_host2" {
  description = "SSH command to connect to Host 2"
  value       = "ssh -i ~/.ssh/ansible.pem ec2-user@${aws_instance.ansible_host2.public_ip}"
}
