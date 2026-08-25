# Environment
region               = "eu-west-2"
environment          = "dev"
project_name         = "Terraform-VPC"

# VPC
vpc_cidr_main        = "10.0.0.0/16"
vpc_cidr_public_a    = "10.0.1.0/24"
vpc_cidr_public_b    = "10.0.2.0/24"
vpc_cidr_private_a   = "10.0.3.0/24"
vpc_cidr_private_b   = "10.0.4.0/24"
default_route_cidr   = "0.0.0.0/0"
availability_zone_a  = "eu-west-2a"
availability_zone_b  = "eu-west-2b"

# S3
bucket_name = "secure-enterprise-file-platform-dev"
