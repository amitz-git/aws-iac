terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.41"
    }
  }
  backend "s3" {
    bucket = "amitz-tfstate"
    key    = "efs/terraform.tfstate"
    region = "ap-south-1"
    
  }
}



