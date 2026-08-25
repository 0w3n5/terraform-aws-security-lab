locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# ===================================================================================================
# MAIN S3 BUCKET

# Main s3 bucket resource
resource "aws_s3_bucket" "files" {
  bucket = var.bucket_name

  tags = merge(local.common_tags, {
    Name = var.bucket_name
  })
}

# bucket versioning
resource "aws_s3_bucket_versioning" "files" {
  bucket = aws_s3_bucket.files.id

  versioning_configuration {
    status = "Enabled"
  }
}

# KMS encryption
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-kms"
  })
}

# KMS key alias
resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}-${var.environment}-s3"
  target_key_id = aws_kms_key.s3.key_id
}


# encrypting the s3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.files.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# block public access
resource "aws_s3_bucket_public_access_block" "bucket_public_access" {
  bucket = aws_s3_bucket.files.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Bucket Owner Enforced 
resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.files.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Bucket Policy
resource "aws_s3_bucket_policy" "files" {
  bucket = aws_s3_bucket.files.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid = "DenyInsecureTransport"

        Effect = "Deny"

        Principal = "*"

        Action = "s3:*"

        Resource = [
          aws_s3_bucket.files.arn,
          "${aws_s3_bucket.files.arn}/*"
        ]

        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ===================================================================================================
# LOGS BUCKET

# Logs bucket resource
resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket_name}-logs"

  tags = merge(local.common_tags, {
    Name = "${var.bucket_name}-logs"
  })
}

# Implement logging for our main bucket "files"
resource "aws_s3_bucket_logging" "files" {
  bucket = aws_s3_bucket.files.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "access-logs/"
}

# Log encryption resource
resource "aws_s3_bucket_server_side_encryption_configuration" "logs_encryption" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Block Public access
resource "aws_s3_bucket_public_access_block" "logs_public_access" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Object Ownership 
resource "aws_s3_bucket_ownership_controls" "logs_ownership" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Logging Bucket Policy
resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid = "AllowS3Logging"

        Effect = "Allow"

        Principal = {
          Service = "logging.s3.amazonaws.com"
        }

        Action = [
          "s3:PutObject"
        ]

        Resource = "${aws_s3_bucket.logs.arn}/*"
      },

      {
        Sid = "DenyInsecureTransport"

        Effect = "Deny"

        Principal = "*"

        Action = "s3:*"

        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]

        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ===================================================================================================
# LIFECYCLE RULES 
resource "aws_s3_bucket_lifecycle_configuration" "files" {
  bucket = aws_s3_bucket.files.id

  rule {
    id     = "lifecycle-rule"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
        noncurrent_days = 30
    }
    abort_incomplete_multipart_upload {
        days_after_initiation = 7
    }
  }
}

# ===================================================================================================
# SECURITY LOG ARCHIVE

# Create the bucket
resource "aws_s3_bucket" "security_logs" {
  bucket = "${var.bucket_name}-security-logs"

  tags = merge(local.common_tags, {
    Name = "${var.bucket_name}-security-logs"
  })
}

# Versioning
resource "aws_s3_bucket_versioning" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# KMS Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "security_logs_encryption" {
  bucket = aws_s3_bucket.security_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# BLOCK PUBLIC ACCESS
resource "aws_s3_bucket_public_access_block" "security_logs_public_access" {
  bucket = aws_s3_bucket.security_logs.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# OBJECT OWNERSHIP
resource "aws_s3_bucket_ownership_controls" "security_logs_ownership" {
  bucket = aws_s3_bucket.security_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# BUCKET POLICY
resource "aws_s3_bucket_policy" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid = "AllowCloudTrail"

        Effect = "Allow"

        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }

        Action = [
          "s3:GetBucketAcl",
          "s3:PutObject"
        ]

        Resource = [
          aws_s3_bucket.security_logs.arn,
          "${aws_s3_bucket.security_logs.arn}/*"
        ]
      },

      {
        Sid = "DenyInsecureTransport"

        Effect = "Deny"

        Principal = "*"

        Action = "s3:*"

        Resource = [
          aws_s3_bucket.security_logs.arn,
          "${aws_s3_bucket.security_logs.arn}/*"
        ]

        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Security log retention
resource "aws_s3_bucket_lifecycle_configuration" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id

  rule {
    id     = "security-log-retention"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}