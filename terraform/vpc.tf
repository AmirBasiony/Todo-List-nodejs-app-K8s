provider "aws" {
  region = var.aws_region
}

###############################
#           VPC              #
###############################
resource "aws_vpc" "AppVPC_K8s" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "AppVPC_K8s"
  }
}

resource "aws_internet_gateway" "AppInternetGateway_K8s" {
  vpc_id = aws_vpc.AppVPC_K8s.id
  tags = {
    Name = "AppInternetGateway_K8s"
  }
}

###############################
#         SUBNETS            #
###############################
resource "aws_subnet" "public_subnet_K8s" {
  vpc_id                  = aws_vpc.AppVPC_K8s.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "public_subnet_K8s"
  }
}


###############################
#      SECURITY GROUPS       #
###############################
resource "aws_security_group" "WebTrafficSG_K8s" {
  name        = "web-traffic-sg"
  description = "Allow app traffic on port 4000"
  vpc_id      = aws_vpc.AppVPC_K8s.id

  ingress {
    from_port   = 4000 #for todo app
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8888 #for argocd NodePort
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 30001 #for todo app NodePort
    to_port     = 30001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "WebTrafficSG_K8s"
  }
}


