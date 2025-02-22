# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "123.45.0.0/16"

  tags = {
    Name = "My Vpc"
  }
}
# Public Subnet
resource "aws_subnet" "pub_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "123.45.10.0/24" 
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Pub Subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "My_IGW"
  }
}

# Routing Table for Public
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "Pub Route Table"
  }
}

# Routing Table Association for Public Subnet
resource "aws_route_table_association" "pub_rt_association" {
  subnet_id      = aws_subnet.pub_subnet.id
  route_table_id = aws_route_table.pub_rt.id  
}

##################################################################

# Private Subnet for ap-south-1a
resource "aws_subnet" "pvt_subnet-1a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "123.45.20.0/24" 
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Pvt Subnet-1a"
  }
}

# Private Subnet for ap-south-1b
resource "aws_subnet" "pvt_subnet-1b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "123.45.30.0/24" 
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "Pvt Subnet-1b"
  }
}

# Routing Table for Private 1a
resource "aws_route_table" "pvt_rt-1a" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "Pvt Rout Table-1a"
  }
}

# Routing Table for Private 1b
resource "aws_route_table" "pvt_rt-1b" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "Pvt Rout Table-1b"
  }
}

# Routing Table Association for Private Subnet 1a
resource "aws_route_table_association" "pvt_rt-1a_association" {
  subnet_id      = aws_subnet.pvt_subnet-1a.id
  route_table_id = aws_route_table.pvt_rt-1a.id
}

# Routing Table Association for Private Subnet 1b
resource "aws_route_table_association" "pvt_rt-1b_ass" {
  subnet_id      = aws_subnet.pvt_subnet-1b.id
  route_table_id = aws_route_table.pvt_rt-1b.id
}

# Internet Gateway Association to Public Routing Table
resource "aws_route" "internet_route" {
  route_table_id         = aws_route_table.pub_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

