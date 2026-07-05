# --- Look up the default VPC and one of its subnets so we don't need to build networking from scratch ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Always grab the latest Ubuntu 22.04 AMI for eu-west-1 rather than hardcoding an AMI ID ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Security group: SSH restricted to your IP, app port + HTTP open for demo access ---
resource "aws_security_group" "app_sg" {
  name        = "b9is121-app-sg"
  description = "Allow SSH from admin IP and app/HTTP traffic from anywhere"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from admin machine only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP - the static site served by Nginx"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "b9is121-app-sg"
    Project = "B9IS121-CA2"
  }
}

# --- The EC2 instance that will run Docker ---
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name    = "b9is121-docker-host"
    Project = "B9IS121-CA2"
  }
}
