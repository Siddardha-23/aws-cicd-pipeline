################################################################################
# VPC
################################################################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

################################################################################
# Public Subnets
################################################################################

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-1"
    Tier = "public"
  })
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-2"
    Tier = "public"
  })
}

################################################################################
# Private Subnets
################################################################################

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-private-1"
    Tier = "private"
  })
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-private-2"
    Tier = "private"
  })
}

################################################################################
# Isolated Subnets
################################################################################

resource "aws_subnet" "isolated_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "us-east-1a"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-isolated-1"
    Tier = "isolated"
  })
}

resource "aws_subnet" "isolated_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "us-east-1b"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-isolated-2"
    Tier = "isolated"
  })
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

################################################################################
# NAT Instance
################################################################################

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "nat" {
  name_prefix = "${var.name_prefix}-nat-"
  description = "Security group for NAT instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow all inbound from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-nat-sg"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-nat-eip"
  })
}

resource "aws_instance" "nat" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.nat.id]
  source_dest_check      = false

  user_data = <<-EOF
    #!/bin/bash
    yum install -y iptables-services
    systemctl enable iptables
    systemctl start iptables
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
    iptables-save > /etc/sysconfig/iptables
  EOF

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-nat-instance"
  })
}

resource "aws_eip_association" "nat" {
  instance_id   = aws_instance.nat.id
  allocation_id = aws_eip.nat.id
}

################################################################################
# Route Tables
################################################################################

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat.primary_network_interface_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-private-rt"
  })
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# Isolated route table (local only)
resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-isolated-rt"
  })
}

resource "aws_route_table_association" "isolated_1" {
  subnet_id      = aws_subnet.isolated_1.id
  route_table_id = aws_route_table.isolated.id
}

resource "aws_route_table_association" "isolated_2" {
  subnet_id      = aws_subnet.isolated_2.id
  route_table_id = aws_route_table.isolated.id
}

################################################################################
# S3 Gateway VPC Endpoint
################################################################################

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.s3"

  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private.id,
  ]

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-s3-endpoint"
  })
}
