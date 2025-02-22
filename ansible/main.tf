terraform {
  backend "s3" {
    bucket = "amitz-tfstate"
    key    = "ansible/terraform.tfstate"
    region = "ap-south-1"
    
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# KEY PAIR
resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "aws_key_pair" "my_keypair" {
  key_name   = "my_key" # Set your desired key pair name
  public_key = tls_private_key.rsa_key.public_key_openssh
}

resource "local_file" "my_key" {
  content  = tls_private_key.rsa_key.private_key_pem
  filename = "${aws_key_pair.my_keypair.key_name}.pem"
}

# SECURITY_GROUP
resource "aws_security_group" "my_sg" {
  name        = "MySecurityGroup"
  description = "Allow inbound SSH and HTTP traffic"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH traffic from any IP
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP traffic from any IP
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP traffic from any IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "PubSecurityGroup"
  }
}


# EC2_INSTANCE 
resource "aws_instance" "ans_engine" {
  ami             = "ami-0449c34f967dbf18a"
  instance_type   = "t2.micro"
  
  key_name        = aws_key_pair.my_keypair.key_name
  vpc_security_group_ids = [aws_security_group.my_sg.id]

  tags = {
    Name = "AnsibleEngine"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y ansible
  EOF
}

resource "aws_instance" "node" {
  depends_on = [ aws_instance.ans_engine ]
  count           = 2
  ami             = "ami-0449c34f967dbf18a"
  instance_type   = "t2.micro"
  
  key_name        = aws_key_pair.my_keypair.key_name
  security_groups = [aws_security_group.my_sg.name]
  
  

  tags = {
    Name = "node${count.index}"
  }
}

resource "local_file" "ssh_connect" {
  content  = "ssh -i ${aws_key_pair.my_keypair.key_name}.pem ec2-user@${aws_instance.ans_engine.public_ip}"
  filename = "ssh_connect.bat"
}

output "Pub_ip" {
  value = [ aws_instance.ans_engine.public_ip, aws_instance.node[*].public_ip]
}