# Create Key Pair and store in local
resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "tf_key" # Set your desired key pair name
  public_key = tls_private_key.rsa_key.public_key_openssh
}

