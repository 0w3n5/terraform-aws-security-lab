# Extablishes the roles that can interact with our secure file transfer

# Common tags ====================================================================================
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Get the AWS account ID =========================================================================
data "aws_caller_identity" "current" {}

# ASSIGN PERMISSION BOUNDARY =====================================================================
# Permission boundary
# Defines the maximum permissions that IAM roles in this
# project are allowed to receive.
resource "aws_iam_policy" "permission_boundary" {
  name        = "${var.project_name}-${var.environment}-PermissionBoundary"
  description = "Maximum permissions allowed for the Secure Enterprise File Platform"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowPlatformServices"
        Effect = "Allow"

        Action = [
          "s3:*",
          "kms:*",
          "ec2:Describe*"
        ]

        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# READ ONLY ROLE =================================================================================
# Read-only IAM role
resource "aws_iam_role" "read_only" {
  name = "${var.project_name}-${var.environment}-ReadOnly"

  permissions_boundary = aws_iam_policy.permission_boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-ReadOnly"
  })
}

# Read-only policy for the Secure Enterprise File Platform 
resource "aws_iam_policy" "read_only" {
  name        = "${var.project_name}-${var.environment}-ReadOnlyPolicy"
  description = "Read-only access to the Secure Enterprise File Platform"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]

        Resource = [
          var.files_bucket_arn,
          "${var.files_bucket_arn}/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

# Attach read-only policy to the read-only role
resource "aws_iam_role_policy_attachment" "read_only" {
  role       = aws_iam_role.read_only.name
  policy_arn = aws_iam_policy.read_only.arn
}

# APPLICATION ROLE ==============================================================================
# APPLICATION ROLE
resource "aws_iam_role" "application" {
  name = "${var.project_name}-${var.environment}-Application"

  permissions_boundary = aws_iam_policy.permission_boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-Application"
  })
}

# APPLICATION ROLE S3 PERMISSIONS 
resource "aws_iam_policy" "application_s3" {
  name        = "${var.project_name}-${var.environment}-Application-S3"
  description = "S3 access for the application"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]

        Resource = "${var.files_bucket_arn}/*"
      },
      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]

        Resource = var.files_bucket_arn
      }
    ]
  })

  tags = local.common_tags
}

# Attach the application policy to the application role
resource "aws_iam_role_policy_attachment" "application_s3" {
  role       = aws_iam_role.application.name
  policy_arn = aws_iam_policy.application_s3.arn
}

# ADMIN ROLE ====================================================================================
# Admin Role
resource "aws_iam_role" "admin" {
  name = "${var.project_name}-${var.environment}-Admin"

  permissions_boundary = aws_iam_policy.permission_boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-Admin"
  })
}

# Admin Policy
resource "aws_iam_policy" "admin" {
  name        = "${var.project_name}-${var.environment}-AdminPolicy"
  description = "Administrative access to the Secure Enterprise File Platform"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:*"
        ]

        Resource = [
          var.files_bucket_arn,
          "${var.files_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "kms:*"
        ]

        Resource = var.kms_key_arn
      },
      {
        Effect = "Allow"

        Action = [
          "ec2:Describe*"
        ]

        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Attach Admin Policy to Admin Role
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = aws_iam_policy.admin.arn
}

