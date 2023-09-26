provider "aws" {
  # Configuration options
  region     = "eu-west-3"
}

resource "aws_vpc" "development-vpc" {
  cidr_block = var.vpc_dev_cidr_block
  tags = {
    name = "development"
  }
}

variable "subnet_cidr_block" {
  description = "cidr block for subnet"
  
}

variable "vpc_dev_cidr_block" {
  description = "vpc cidr block dev"
}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id = aws_vpc.development-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = "eu-west-3a"
  tags = {
    name:  "dev-subnet-1"
  }
}

# outputs the name on each id
output "development-vpc-id" {
  value = aws_vpc.development-vpc.id 
}

output "dev-subnet-1-id" {
  value = aws_subnet.dev-subnet-1.id
}