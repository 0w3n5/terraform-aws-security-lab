variable "vpc_cidr_main" {
  description = "CIDR block for the main VPC"
  type        = string

  validation {
    condition = can(cidrhost(var.vpc_cidr_main, 0))
    error_message = "The provided value must be a valid IPv4 or IPv6 CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "vpc_cidr_public_a" {
  description = "CIDR block for the public subnet of the VPC"
  type        = string

  validation {
    condition = can(cidrhost(var.vpc_cidr_public_a, 0))
    error_message = "The provided value must be a valid IPv4 or IPv6 CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "vpc_cidr_public_b" {
  description = "CIDR block for the public subnet of the VPC"
  type        = string

  validation {
    condition = can(cidrhost(var.vpc_cidr_public_b, 0))
    error_message = "The provided value must be a valid IPv4 or IPv6 CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "vpc_cidr_private_a" {
  description = "CIDR block for the private subnet in the VPC"
  type        = string

  validation {
    condition = can(cidrhost(var.vpc_cidr_private_a, 0))
    error_message = "The provided value must be a valid IPv4 or IPv6 CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "vpc_cidr_private_b" {
  description = "CIDR block for the private subnet in the VPC"
  type        = string

  validation {
    condition = can(cidrhost(var.vpc_cidr_private_b, 0))
    error_message = "The provided value must be a valid IPv4 or IPv6 CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "default_route_cidr" {
  description = "CIDR block for the VPC Internet Gateway"
  type        = string

  validation {
    condition = can(cidrhost(var.default_route_cidr, 0))
    error_message = "The provided value must be a valid IPv4 or IPv6 CIDR block (e.g., 10.0.0.0/16)."
  }
}

# Availability zones
variable "availability_zone_a" {
  description = "Availability Zone for the first public/private subnet pair."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", var.availability_zone_a))
    error_message = "Availability Zone must be in the format eu-west-2a."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either dev or prod."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "availability_zone_b" {
  description = "Availability Zone for the second public/private subnet pair."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", var.availability_zone_b))
    error_message = "Availability Zone must be in the format eu-west-2b."
  }
}