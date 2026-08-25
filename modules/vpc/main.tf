# Common tags
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# vpc resource - creates your isolated aws network
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_main

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-Main-VPC"
  })
}

# internet gateway - attaches your VPC to the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-Main-Internet-Gateway"
  })
}

# public subnet - creates a public subnet to host things like: 
# web servers, load balancers and bastion hosts
# This network exists from 10.0.1.0 to 10.0.1.255
resource "aws_subnet" "public_a" {
 vpc_id = aws_vpc.main.id
 cidr_block = var.vpc_cidr_public_a
 map_public_ip_on_launch = true
 availability_zone = var.availability_zone_a

 tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-Public-Subnet-a"
 })
}

resource "aws_subnet" "public_b" {
 vpc_id = aws_vpc.main.id
 cidr_block = var.vpc_cidr_public_b
 map_public_ip_on_launch = true
 availability_zone = var.availability_zone_b

 tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-Public-Subnet-b"
 })
}


# private subnet - creates a private subnet to host things like: 
# databases, internal servers and backend services
# This network exists from 10.0.2.0 to 10.0.2.255
# only allows private IP's and no internet access
# split into availability zones into a and b
resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.vpc_cidr_private_a
  availability_zone = var.availability_zone_a

  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-Private-Subnet-a"
  })
}
resource "aws_subnet" "private_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.vpc_cidr_private_b
  availability_zone = var.availability_zone_b

  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-Private-Subnet-b"
  })
}


# public route table - tells aws where the traffic should go
# e.g. 0.0.0.0/0 = Internet Gateway meaning can access anywhere 
# on the internet
resource "aws_route_table" "public_rt" {
 vpc_id = aws_vpc.main.id
 tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-Public-RT"
  })
 route {
   cidr_block = var.default_route_cidr
   gateway_id = aws_internet_gateway.gw.id
 }
}

resource "aws_route_table_association" "public_assoc_a" {
 subnet_id = aws_subnet.public_a.id
 route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_b" {
 subnet_id = aws_subnet.public_b.id
 route_table_id = aws_route_table.public_rt.id
}

# private route table - creates routing for private resources
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-Private-RT"
  })

  route {
  cidr_block     = var.default_route_cidr
  nat_gateway_id = aws_nat_gateway.main.id
  }
}

resource "aws_route_table_association" "private_assoc_a" {
 subnet_id = aws_subnet.private_a.id
 route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_b" {
 subnet_id = aws_subnet.private_b.id
 route_table_id = aws_route_table.private_rt.id
}

# VPC Elastic IP for the NAT gateway
resource "aws_eip" "nat" {

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-Elastic-IP"
  })
}

# NAT gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [
    aws_internet_gateway.gw
  ]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-NAT-Gateway"
  })
}

# ===================================================================================================
# VPC FLOW LOGS

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-VPC-Flow-Logs"
  })
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-VPCFlowLogs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-VPCFlowLogs"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-VPC-Flow-Logs"
  })
}