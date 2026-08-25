variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either dev or prod."
  }
}

variable "files_bucket_arn" {
  description = "ARN of the main S3 files bucket"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the S3 bucket"
  type        = string
}