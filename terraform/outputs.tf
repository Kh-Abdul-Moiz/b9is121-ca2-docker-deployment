output "instance_public_ip" {
  description = "Public IP address of the EC2 instance running Docker"
  value       = aws_instance.app_server.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app_server.id
}

output "security_group_id" {
  description = "Security group ID attached to the instance"
  value       = aws_security_group.app_sg.id
}
