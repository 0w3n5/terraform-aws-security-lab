output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.files.bucket
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.files.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for S3 encryption"
  value       = aws_kms_key.s3.arn
}

output "files_bucket_arn" {
  description = "ARN of the main S3 files bucket"
  value       = aws_s3_bucket.files.arn
}

output "security_log_bucket_name" {
  description = "Name of the S3 bucket used for security logs"
  value       = aws_s3_bucket.security_logs.id
}

output "security_log_bucket_arn" {
  description = "ARN of the S3 bucket used for security logs"
  value       = aws_s3_bucket.security_logs.arn
}