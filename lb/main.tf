terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "amitz-tfstate"
    key    = "lb/terraform.tfstate"
    region = "ap-south-1"
    
  }
}

provider "aws" {
  region     = "ap-south-1"
}

# Instances
resource "aws_instance" "pub_ins" {
  ami           = "ami-0a0f1259dd1c90938"
  instance_type = "t2.micro"
  
  subnet_id = aws_subnet.pub_subnet.id
  vpc_security_group_ids = [aws_security_group.pub_sg.id]
  key_name = "aws/key.pem" # Use existing key pair

  tags = {
    Name = "Pub"
  }

  user_data = <<-EOF
  #! /bin/bash
  sudo yum update -y
  sudo yum install httpd git java -y
  sudo service httpd start
  sudo chkconfig httpd on
  cd /var/www/html
  sudo git clone https://github.com/amitzrepo/carwebsite.git .
  sudo service httpd restart
  EOF

}

resource "aws_instance" "pub_ins2" {
  ami           = aws_instance.pub_ins.ami
  instance_type = "t2.micro"
  
  subnet_id = aws_subnet.pub_subnet.id
  vpc_security_group_ids = [aws_security_group.pub_sg.id]
  key_name = aws_instance.pub_ins.key_name
  //key_name = "my_key" # Use existing key pair

  tags = {
    Name = "Pub"
  }

  user_data = <<-EOF
  #! /bin/bash
  yum update -y
  yum install httpd -y
  service httpd start
  chkconfig httpd on
  cd /var/www/html
  echo "2nd Server" > index.html
  service httpd restart
  EOF

}



resource "aws_instance" "pvt_ins-1" {
  ami           = aws_instance.pub_ins.ami
  instance_type = "t2.micro"
  
  subnet_id = aws_subnet.pvt_subnet-1a.id
  vpc_security_group_ids = [aws_security_group.pvt_sg.id]
  key_name = aws_instance.pub_ins.key_name
  
  tags = {
    Name = "Pvt 1a"
  }

  user_data = <<-EOF
  #! /bin/bash
  sudo yum update -y
  sudo yum install httpd git java -y
  sudo service httpd start
  sudo chkconfig httpd on
  echo "Pvt Instance 1" > /var/www/html/index.html
  sudo service httpd restart
  EOF

}

resource "aws_instance" "pvt_ins-2" {
  ami           = aws_instance.pub_ins.ami
  instance_type = "t2.micro"
  
  subnet_id = aws_subnet.pvt_subnet-1b.id
  vpc_security_group_ids = [aws_security_group.pvt_sg.id]
  key_name = aws_key_pair.my_key_pair.key_name

  tags = {
    Name = "Pvt 1b"
  }

  user_data = <<-EOF
  #! /bin/bash
  sudo yum update -y
  sudo yum install httpd git java -y
  sudo service httpd start
  sudo chkconfig httpd on
  echo "Pvt Instance 2" > /var/www/html/index.html
  sudo service httpd restart
  EOF
}