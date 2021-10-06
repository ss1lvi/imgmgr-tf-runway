terraform {
  backend "s3" {
    key = "vpc.tfstate"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

resource "aws_vpc" "TFtopVPC" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${var.customer}-${var.environment} VPC"
  }
}

resource "aws_internet_gateway" "TFtopIGW" {
  vpc_id = aws_vpc.TFtopVPC.id
  tags = {
    Name = "${var.customer}-${var.environment} IGW"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "TFtopSubnetPub1" {
  vpc_id                  = aws_vpc.TFtopVPC.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "10.220.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.customer}-${var.environment} Public Subnet 1"
  }
}

resource "aws_subnet" "TFtopSubnetPub2" {
  vpc_id                  = aws_vpc.TFtopVPC.id
  availability_zone       = data.aws_availability_zones.available.names[1]
  cidr_block              = "10.220.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.customer}-${var.environment} Public Subnet 2"
  }
}

resource "aws_subnet" "TFtopSubnetPriv1" {
  vpc_id                  = aws_vpc.TFtopVPC.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "10.220.3.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.customer}-${var.environment} Private Subnet 1"
  }
}

resource "aws_subnet" "TFtopSubnetPriv2" {
  vpc_id                  = aws_vpc.TFtopVPC.id
  availability_zone       = data.aws_availability_zones.available.names[1]
  cidr_block              = "10.220.4.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.customer}-${var.environment} Private Subnet 2"
  }
}

resource "aws_eip" "TFtopNatEIPs" {
  count = 2
}

resource "aws_nat_gateway" "TFtopNat1" {
  subnet_id     = aws_subnet.TFtopSubnetPub1.id
  allocation_id = aws_eip.TFtopNatEIPs[0].id
  depends_on    = [aws_internet_gateway.TFtopIGW]
  tags = {
    Name = "${var.customer}-${var.environment} NAT Gateway 1"
  }
}

resource "aws_nat_gateway" "TFtopNat2" {
  subnet_id     = aws_subnet.TFtopSubnetPub2.id
  allocation_id = aws_eip.TFtopNatEIPs[1].id
  depends_on    = [aws_internet_gateway.TFtopIGW]
  tags = {
    Name = "${var.customer}-${var.environment} NAT Gateway 2"
  }
}

resource "aws_route_table" "TFtopPubRT" {
  vpc_id     = aws_vpc.TFtopVPC.id
  depends_on = [aws_internet_gateway.TFtopIGW]
  route {
    gateway_id = aws_internet_gateway.TFtopIGW.id
    cidr_block = "0.0.0.0/0"
  }
  tags = {
    Name = "${var.customer}-${var.environment} Public Route Table"
  }
}

resource "aws_route_table" "TFtopPrivRT1" {
  vpc_id     = aws_vpc.TFtopVPC.id
  depends_on = [aws_nat_gateway.TFtopNat1]
  route {
    nat_gateway_id = aws_nat_gateway.TFtopNat1.id
    cidr_block     = "0.0.0.0/0"
  }
  tags = {
    Name = "${var.customer}-${var.environment} Private Route Table 1"
  }
}

resource "aws_route_table" "TFtopPrivRT2" {
  vpc_id     = aws_vpc.TFtopVPC.id
  depends_on = [aws_nat_gateway.TFtopNat2]
  route {
    nat_gateway_id = aws_nat_gateway.TFtopNat2.id
    cidr_block     = "0.0.0.0/0"
  }
  tags = {
    Name = "${var.customer}-${var.environment} Private Route Table 2"
  }
}

resource "aws_route_table_association" "TFtopPub1RTAssociation" {
  subnet_id      = aws_subnet.TFtopSubnetPub1.id
  route_table_id = aws_route_table.TFtopPubRT.id
}

resource "aws_route_table_association" "TFtopPub2RTAssociation" {
  subnet_id      = aws_subnet.TFtopSubnetPub2.id
  route_table_id = aws_route_table.TFtopPubRT.id
}

resource "aws_route_table_association" "TFtopPriv1RTAssociation" {
  subnet_id      = aws_subnet.TFtopSubnetPriv1.id
  route_table_id = aws_route_table.TFtopPrivRT1.id
}

resource "aws_route_table_association" "TFtopPriv2RTAssociation" {
  subnet_id      = aws_subnet.TFtopSubnetPriv2.id
  route_table_id = aws_route_table.TFtopPrivRT2.id
}

# outputs

output "vpc_id" {
  value = aws_vpc.TFtopVPC.id
}

output "availability_zones" {
  value = [aws_subnet.TFtopSubnetPriv1.availability_zone, aws_subnet.TFtopSubnetPriv2.availability_zone]
}

output "public_subnets" {
  value = [aws_subnet.TFtopSubnetPub1.id, aws_subnet.TFtopSubnetPub2.id]
}

output "private_subnets" {
  value = [aws_subnet.TFtopSubnetPriv1.id, aws_subnet.TFtopSubnetPriv2.id]
}