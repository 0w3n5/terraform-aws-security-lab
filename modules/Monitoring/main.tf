locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# ==================================================================================================
# CLOUDTRAIL 
resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-${var.environment}-cloudtrail"
  s3_bucket_name                = var.security_log_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch.arn

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-CloudTrail"
  })
}

# ===================================================================================================
# CLOUDWATCH LOGGING
# Stores 30 days of hot/searchable logs in CloudWatch
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-CloudTrail-Logs"
  })
}

# IAM Role
resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "${var.project_name}-${var.environment}-CloudTrail-CloudWatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy
resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "${var.project_name}-${var.environment}-CloudTrail-CloudWatch"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# ===================================================================================================
# CLOUDWATCH METRIC FILTERS

resource "aws_cloudwatch_log_metric_filter" "root_account_usage" {
  name           = "${var.project_name}-${var.environment}-RootAccountUsage"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"

  metric_transformation {
    name      = "RootAccountUsage"
    namespace = "${var.project_name}/${var.environment}/Security"
    value     = "1"
  }
}

# Alarm 
resource "aws_cloudwatch_metric_alarm" "root_account_usage" {
  alarm_name          = "${var.project_name}-${var.environment}-RootAccountUsage"
  alarm_description   = "Detects usage of the AWS root account."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootAccountUsage"
  namespace           = "${var.project_name}/${var.environment}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  treat_missing_data = "notBreaching"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-RootAccountUsage"
  })
}

# IAM Change Policy Detection
resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name           = "${var.project_name}-${var.environment}-IAMPolicyChanges"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  pattern = "{ ($.eventSource = \"iam.amazonaws.com\") && (($.eventName = \"CreatePolicy\") || ($.eventName = \"DeletePolicy\") || ($.eventName = \"CreatePolicyVersion\") || ($.eventName = \"DeletePolicyVersion\") || ($.eventName = \"SetDefaultPolicyVersion\") || ($.eventName = \"PutRolePolicy\") || ($.eventName = \"PutUserPolicy\") || ($.eventName = \"PutGroupPolicy\") || ($.eventName = \"DeleteRolePolicy\") || ($.eventName = \"DeleteUserPolicy\") || ($.eventName = \"DeleteGroupPolicy\") ) }"

  metric_transformation {
    name      = "IAMPolicyChanges"
    namespace = "${var.project_name}/${var.environment}/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_policy_changes" {
  alarm_name          = "${var.project_name}-${var.environment}-IAMPolicyChanges"
  alarm_description   = "Detects changes to IAM policies."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "IAMPolicyChanges"
  namespace           = "${var.project_name}/${var.environment}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  treat_missing_data = "notBreaching"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-IAMPolicyChanges"
  })
}

# ===================================================================================================
# AWS CONFIG

resource "aws_iam_role" "config" {
  name = "${var.project_name}-${var.environment}-AWSConfig"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "config.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# Configuration recorder
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-${var.environment}-config"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# Delivery Channel
resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-${var.environment}-config"
  s3_bucket_name = var.security_log_bucket_name

  depends_on = [
    aws_config_configuration_recorder.main
  ]
}

# Config recorder Status 
resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [
    aws_config_delivery_channel.main
  ]
}

resource "aws_cloudwatch_log_metric_filter" "security_group_changes" {
  name           = "${var.project_name}-${var.environment}-SecurityGroupChanges"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  pattern = "{ ($.eventSource = \"ec2.amazonaws.com\") && (($.eventName = \"AuthorizeSecurityGroupIngress\") || ($.eventName = \"AuthorizeSecurityGroupEgress\") || ($.eventName = \"RevokeSecurityGroupIngress\") || ($.eventName = \"RevokeSecurityGroupEgress\") || ($.eventName = \"CreateSecurityGroup\") || ($.eventName = \"DeleteSecurityGroup\") ) }"

  metric_transformation {
    name      = "SecurityGroupChanges"
    namespace = "${var.project_name}/${var.environment}/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "security_group_changes" {
  alarm_name          = "${var.project_name}-${var.environment}-SecurityGroupChanges"
  alarm_description   = "Detects changes to VPC security groups."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "SecurityGroupChanges"
  namespace           = "${var.project_name}/${var.environment}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  treat_missing_data = "notBreaching"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-SecurityGroupChanges"
  })
}