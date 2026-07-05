variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-1"
}

variable "instance_type" {
  description = "EC2 instance type (t2.micro is free-tier eligible)"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of an EXISTING EC2 key pair in your AWS account, used for SSH access"
  type        = string
}

variable "my_ip" {
  description = "Your current public IP in CIDR notation (e.g. 203.0.113.10/32), used to restrict SSH"
  type        = string
}

