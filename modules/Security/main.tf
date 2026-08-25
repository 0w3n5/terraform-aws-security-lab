variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# ===================================================================================================
# GUARDDUTY

resource "aws_guardduty_detector" "main" {
  enable = true

  finding_publishing_frequency = "FIFTEEN_MINUTES"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-GuardDuty"
  })
}

resource "aws_guardduty_detector_feature" "s3_protection" {
  detector_id = aws_guardduty_detector.main.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}


# ===================================================================================================
# SECURITY HUB

resource "aws_securityhub_account" "main" {
  enable_default_standards = true

  depends_on = [
    aws_guardduty_detector.main
  ]
}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"

  depends_on = [
    aws_securityhub_account.main
  ]
}