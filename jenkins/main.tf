terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.41"
    }

    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }
  }
  backend "s3" {
    bucket = "tfpocbucket001"
    key    = "jenkins-pipeline/terraform.tfstate"
    region = "eu-north-1"
  }
}

provider "aws" {
  region = local.region
}

locals {
  region = "ap-south-2"

  ami           = "ami-0e386fa0b67b8b12c"
  instance_type = "t3.micro"
  name          = "jenkins"
  roles         = ["master", "docker", "terraform"]
}

# default
# VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# SECURITY GROUP
resource "aws_security_group" "custom" {
  name   = "${local.name}-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-sg" }
}

resource "aws_network_interface" "custom" {
  count = length(local.roles)

  subnet_id       = data.aws_subnets.default.ids[0]
  security_groups = [aws_security_group.custom.id]

  tags = { Name = "${local.name}-ni-${count.index + 1}" }
}

#ssh-keygen -t rsa -b 4096 -f ./keypair/id_rsa
resource "tls_private_key" "custom" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "custom" {
  key_name   = "id_rsa"
  public_key = tls_private_key.custom.public_key_openssh
}

#EC2
resource "aws_instance" "tools_vm" {
  depends_on = [
    aws_network_interface.custom
  ]

  count = length(local.roles)

  ami           = local.ami
  instance_type = local.instance_type

  network_interface {
    network_interface_id = aws_network_interface.custom[count.index].id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  key_name = aws_key_pair.custom.key_name
  tags     = { Name = "${local.roles[count.index]}-${count.index + 1}" }
}

output "ssh_key" {
  value     = tls_private_key.custom.private_key_pem
  sensitive = true
}

output "vm_ips" {
  value = [for instance in aws_instance.tools_vm : "${instance.tags.Name} - ${instance.public_ip}"]
}

# ansible ansible-inventory -i inventory.yml --list (show the inventory)
resource "ansible_host" "hosts" {
  for_each = { for idx, instance in aws_instance.tools_vm : idx => instance }

  name   = each.value.public_ip
  groups = [try(local.roles[each.key], "extra")] # Assigns predefined role or "extra" for additional instances
  variables = {
    name                         = try(local.roles[each.key], "extra-${each.key}") # Assigns unique name for extra instances
    ansible_user                 = "ubuntu"
    ansible_ssh_private_key_file = "id_rsa.pem"
    ansible_connection           = "ssh"
    ansible_ssh_common_args      = "-o StrictHostKeyChecking=no"
    ansible_python_interpreter   = "/usr/bin/python3"
  }
}