terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "kijanikiosk-tf-state" # Must be globally unique
    key    = "staging/terraform.tfstate"
    region = "us-east-1"
    # DynamoDB table would be specified here for production state locking
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Assuming default VPC for the lab environment
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "app" {
  name        = "kijanikiosk-app-sg"
  description = "Security group for KijaniKiosk app servers"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from anywhere (restrict in prod)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  servers = {
    api = {
      instance_type = "t3.micro"
    }
    payments = {
      instance_type = "t3.micro"
    }
    logs = {
      instance_type = "t3.micro"
    }
  }
}

module "app_servers" {
  source   = "./modules/app_server"
  for_each = local.servers

  name                   = each.key
  environment            = var.environment
  instance_type          = each.value.instance_type
  ami_id                 = data.aws_ami.ubuntu.id
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = var.ssh_key_name
}