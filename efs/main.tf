# VPC
resource "aws_default_vpc" "foo" {
  tags = {
    Name = "default"
  }
}

# SUBNET
resource "aws_default_subnet" "foo-az1" {
  availability_zone = "ap-south-1a"

  tags = {
    Name = "default"
  }
}

# Create Key Pair and store in local
resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "tf_key" # Set your desired key pair name
  public_key = tls_private_key.rsa_key.public_key_openssh
}

# Local copy of key_pair
resource "local_file" "tf_key" {
  content  = tls_private_key.rsa_key.private_key_pem
  filename = "tf_key.pem"
}

resource "local_file" "tf_key_ansible" {
  content  = tls_private_key.rsa_key.private_key_pem
  filename = "C:/Users/amitk/aws/efs/ansible/tf_key.pem"
}

# SECURITY GROUP
resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Allow SSH and Http inbound traffic"
  vpc_id      = aws_default_vpc.foo.id

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
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-efs"
  }
}

# NETWORK INTERFACE
resource "aws_network_interface" "foo" {
  count       = 2
  subnet_id   = aws_default_subnet.foo-az1.id

  security_groups = [aws_security_group.ec2.id]
  tags = {
    Name = "ec2-efs"
  }
}


# EC2
resource "aws_instance" "foo" {
  depends_on = [ aws_efs_file_system.foo, aws_efs_mount_target.foo ]
  count         = 2
  ami           = "ami-007020fd9c84e18c7" # Ubuntu
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_key_pair.key_name

  network_interface {
    network_interface_id  = aws_network_interface.foo[count.index].id
    device_index          = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  user_data = <<-EOF
              #!/bin/bash
                  apt-get update -y
                  apt-get install -y nginx
                  apt-get install nfs-common -y
              EOF

  tags = {
    Name = "ec2-efs-${count.index}"
  }
}

# can be used in user data too as follow
# sudo mkdir /home/ec2-user/efs
# sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.foo.dns_name}:/ /home/ec2-user/efs


# EFS
resource "aws_efs_file_system" "foo" {
  creation_token  = "efs-ec2-lb-example"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "ec2-efs"
  }
}

resource "aws_security_group" "efs" {
  name        = "efs-sg"
  description = "Allow ec2-sg will talk to this efs"
  vpc_id      = aws_default_vpc.foo.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # ec2-sg
    security_groups = [ aws_security_group.ec2.id ]
  }

  tags = {
    Name = "ec2-efs"
  }
}

resource "aws_efs_mount_target" "foo" {
  file_system_id  = aws_efs_file_system.foo.id
  subnet_id       = aws_default_subnet.foo-az1.id
  security_groups = [ aws_security_group.efs.id ]
}

output "ec2_host_public_ip" {
  value = aws_instance.foo[*].public_ip
}

output "efs_hostname" {
  value = aws_efs_file_system.foo.dns_name
}

locals {
  template_vars = {
    ec2_hosts             = [for ip in aws_instance.foo[*].public_ip : "${ip}"]
    efs_hostname          = aws_efs_file_system.foo.dns_name
    ssh_private_key_file  = "${aws_key_pair.my_key_pair.key_name}.pem"
  }
}

resource "local_file" "foo" {
  content  = templatefile("${path.module}/ansible/inventory.ini.tftpl", local.template_vars)
  filename = "${path.module}/ansible/inventory.ini"
}
