output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.main.id
}

output "guardduty_detector_arn" {
  description = "GuardDuty detector ARN"
  value       = aws_guardduty_detector.main.arn
}

output "security_hub_arn" {
  description = "Security Hub account ARN"
  value       = aws_securityhub_account.main.arn
}