# AWS Provider configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}

# Data source for target account (in real scenario, this would be different)
# For this lab, we'll use the same account but demonstrate the pattern
data "aws_caller_identity" "target" {
  provider = aws
}

# Create IAM policy for AssumeRole permission
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      aws_iam_role.s3_access_role.arn
    ]
  }
}

# Create IAM user for testing (represents developer in Account A)
resource "aws_iam_user" "developer" {
  name = "${var.lab_name}-developer"
  path = "/lab-users/"

  tags = {
    Lab         = var.lab_name
    Environment = "learning"
    CreatedBy   = "aws-cert-prep-lab"
    Purpose     = "cross-account-access-demo"
  }
}

# Attach AssumeRole policy to developer user
resource "aws_iam_user_policy" "developer_assume_role" {
  name   = "${var.lab_name}-assume-role-policy"
  user   = aws_iam_user.developer.name
  policy = data.aws_iam_policy_document.assume_role_policy.json
}

# Create access keys for developer user (for CLI testing)
resource "aws_iam_access_key" "developer_key" {
  user = aws_iam_user.developer.name

  # Note: In production, use temporary credentials instead
  lifecycle {
    create_before_destroy = true
  }
}

# Trust policy for the cross-account role
data "aws_iam_policy_document" "trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_user.developer.arn,
        # In real cross-account scenario, this would be:
        # "arn:aws:iam::${var.source_account_id}:user/${var.source_user_name}"
      ]
    }
    actions = ["sts:AssumeRole"]
    
    # Optional: Add conditions for enhanced security
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
    
    condition {
      test     = "NumericLessThan"
      variable = "aws:TokenIssueTime"
      values   = [tostring(timestamp())]
    }
  }
}

# S3 access policy for the role
data "aws_iam_policy_document" "s3_access_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.target_bucket.arn,
      "${aws_s3_bucket.target_bucket.arn}/*"
    ]
  }
  
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets"
    ]
    resources = ["*"]
  }
}

# IAM role that can be assumed (represents role in Account B)
resource "aws_iam_role" "s3_access_role" {
  name               = "${var.lab_name}-s3-access-role"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json
  path               = "/lab-roles/"

  tags = {
    Lab         = var.lab_name
    Environment = "learning"
    CreatedBy   = "aws-cert-prep-lab"
    Purpose     = "cross-account-s3-access"
  }
}

# Attach S3 policy to the role
resource "aws_iam_role_policy" "s3_access" {
  name   = "${var.lab_name}-s3-access-policy"
  role   = aws_iam_role.s3_access_role.id
  policy = data.aws_iam_policy_document.s3_access_policy.json
}

# S3 bucket for testing access (represents resource in Account B)
resource "aws_s3_bucket" "target_bucket" {
  bucket        = "${var.lab_name}-target-bucket-${random_string.bucket_suffix.result}"
  force_destroy = true # Allows terraform destroy even with objects

  tags = {
    Lab         = var.lab_name
    Environment = "learning"
    CreatedBy   = "aws-cert-prep-lab"
    Purpose     = "cross-account-access-target"
  }
}

# Random string for unique bucket naming
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket versioning configuration
resource "aws_s3_bucket_versioning" "target_bucket_versioning" {
  bucket = aws_s3_bucket.target_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket public access block (security best practice)
resource "aws_s3_bucket_public_access_block" "target_bucket_pab" {
  bucket = aws_s3_bucket.target_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload a sample file to the bucket for testing
resource "aws_s3_object" "sample_file" {
  bucket  = aws_s3_bucket.target_bucket.id
  key     = "sample-data/test-file.txt"
  content = "This is a test file for the cross-account access lab.\nIf you can read this, AssumeRole is working correctly!"
  
  tags = {
    Lab         = var.lab_name
    Environment = "learning"
    CreatedBy   = "aws-cert-prep-lab"
  }
}
