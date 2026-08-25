# VPC
module "vpc" {
  source = "../../modules/vpc"
  
  environment = var.environment
  project_name = var.project_name

  vpc_cidr_main       = var.vpc_cidr_main

  vpc_cidr_public_a   = var.vpc_cidr_public_a
  vpc_cidr_public_b   = var.vpc_cidr_public_b

  vpc_cidr_private_a  = var.vpc_cidr_private_a
  vpc_cidr_private_b  = var.vpc_cidr_private_b

  availability_zone_a = var.availability_zone_a
  availability_zone_b = var.availability_zone_b

  default_route_cidr  = var.default_route_cidr
}

# S3
module "s3" {
  source = "../../modules/s3"

  bucket_name = var.bucket_name

  environment = var.environment
  project_name = var.project_name
  security_log_bucket_name = module.s3.security_log_bucket_name
}

# IAM
module "iam" {
  source = "../../modules/iam"

  project_name     = var.project_name
  environment      = var.environment
  files_bucket_arn = module.s3.files_bucket_arn
  kms_key_arn      = module.s3.kms_key_arn
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_name             = var.project_name
  environment              = var.environment
  security_log_bucket_name = module.s3.security_log_bucket_name
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
}