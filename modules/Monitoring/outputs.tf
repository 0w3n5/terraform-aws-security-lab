output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.main.arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group containing CloudTrail events"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

