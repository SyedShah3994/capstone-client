terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }
}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["capstone-vpc"]
  }
}

data "aws_subnet" "client" {
  filter {
    name   = "tag:Name"
    values = ["capstone-client-subnet"]
  }
}

resource "aws_security_group" "client" {
  name        = "capstone-client-sg"
  description = "Client VM access"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = "Ping from inside the VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Grafana"
    from_port   = 3020
    to_port     = 3020
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "capstone-client-sg" }
}

resource "aws_key_pair" "client" {
  key_name   = "capstone-client-key"
  public_key = file("${path.module}/capstone_key.pub")
}

resource "aws_instance" "client" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnet.client.id
  vpc_security_group_ids = [aws_security_group.client.id]
  key_name               = aws_key_pair.client.key_name
  user_data              = file("${path.module}/user_data.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = { Name = "capstone-client-vm" }
}
