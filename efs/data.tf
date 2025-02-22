data "aws_vpc" "selected" {
  id = aws_default_vpc.foo.id
}

data "aws_subnet" "subnet" {
    availability_zone = "ap-south-1a"    
}

