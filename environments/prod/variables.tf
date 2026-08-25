variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "eu-west-2"
}

variable "vpc_cidr_main" {}
variable "vpc_cidr_public" {}
variable "vpc_cidr_private" {}
variable "default_route_cidr" {}
