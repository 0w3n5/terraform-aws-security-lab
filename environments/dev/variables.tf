variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "eu-west-2"
  
  validation {
    condition = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2",
      "af-south-1", "ap-east-1", "ap-south-1", "ap-south-2",
      "ap-southeast-1", "ap-southeast-2", "ap-southeast-3",
      "ap-northeast-1", "ap-northeast-2", "ap-northeast-3",
      "ca-central-1",
      "eu-central-1", "eu-central-2",
      "eu-west-1", "eu-west-2", "eu-west-3",
      "eu-north-1", "eu-south-1", "eu-south-2",
      "me-south-1", "me-central-1",
      "sa-east-1"
    ], var.region)

    error_message = "Please provide a valid AWS region."
  }
}

variable "availability_zone_a" {
  description = "Primary Availability Zone"
  type        = string
}

variable "availability_zone_b" {
  description = "Secondary Availability Zone"
  type        = string
}

variable "environment" {
  description = "The active environment the resource belongs in"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "project_name" {
  description = "The name of this project"
  type        = string
}

# VPC variables
variable "vpc_cidr_main" {}
variable "vpc_cidr_public_a" {}
variable "vpc_cidr_public_b" {}
variable "vpc_cidr_private_a" {}
variable "vpc_cidr_private_b" {}
variable "default_route_cidr" {}


# S3 variables
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}