
resource "aws_vpc" "twk" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-vpc"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "dev" {
  vpc_id                  = aws_vpc.twk.id
  cidr_block              = var.dev_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-subnet-dev"
  })
}

resource "aws_internet_gateway" "twk-igw" {
  vpc_id = aws_vpc.twk.id

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-igw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.twk.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.twk-igw.id
  }

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "dev-rt" {
  subnet_id      = aws_subnet.dev.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "dev-sg" {
  name_prefix = "${var.env_prefix}-sg-dev-"
  description = "TWK dev server: restricted SSH, public HTTP and HTTPS"
  vpc_id      = aws_vpc.twk.id

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-sg-dev"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.dev-sg.id
  description       = "SSH from approved owner IP"
  cidr_ipv4         = var.ssh_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.dev-sg.id
  description       = "Public HTTP"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.dev-sg.id
  description       = "Public HTTPS"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.dev-sg.id
  description       = "Allow outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
