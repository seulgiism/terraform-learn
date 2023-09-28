provider "aws" {
  # Configuration options
  region = "eu-west-3"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable allowed_ips {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    name:  "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    name = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-internet-gateway" {
  vpc_id = aws_vpc.myapp-vpc.id

    tags = {
      Name: "${var.env_prefix}-internet-gateway"
    }
}

resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.myapp-internet-gateway.id
    }
    tags = {
      Name: "${var.env_prefix}-rtb"
    }
}

resource "aws_route_table_association" "myapp-subnet-associations" {
  subnet_id = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
  
}

resource "aws_security_group" "myapp-security-group" {
    name = "${var.env_prefix}-security-group"
    vpc_id = aws_vpc.myapp-vpc.id
    
    ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"

      # here we are using the variable and the values set in terraform.tfvars, 
      # in case we want people we are working with to add their own ips to the list they can add it to the list set-up there:

      cidr_blocks = var.allowed_ips
    }

    ingress {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"

      # here we are defining the internet gateway IP. We want everyone to be able to access our nginx webserver on port 8080
      # hence why we are allowing the port range from 8080 to 8080:

      # Ingress means incomming and Egress means exiting.

      cidr_blocks = ["0.0.0.0/0"]
    }

    # Why use egress? basically in case we want to install docker or other programs from the VPC we want it to be able to
    # connect it to the internet.. installation, binaries, linux packages.
    # We don't want to restrict it on ANY port nor PROTOCOl... so use 0 to 0 and -1
    # also prefix_list_ids allows the vpc to connect to all other end points

    egress {
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
     prefix_list_ids = []
    }
    tags = {
      name: "${var.env_prefix}-security-group"
    }
}

# here we are filtering for amazon's latest linux os, with 2 required values and a filter that filters on name from the
# amazon marketplace. we added a "*" in between so that we only get images that starts with al2023-ami- and ends with x86_64

  data "aws_ami" "amazon-latest-linux-os" {
    most_recent = true
    owners = ["amazon"]

    filter {
      name = "name"
      values = ["al2023-ami-*-x86_64"]
    }
    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }
  }

  resource "aws_instance" "myapp-server" {
    # we actually want this ID not directly from Amazon, but through TerraForm so that it can change dynamically over time
    # ami = "ami-0fc067f03ad87bb64"
    # see the above block data

    ami = data.aws_ami.amazon-latest-linux-os.id
    
  }