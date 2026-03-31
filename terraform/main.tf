terraform {
  cloud {
    organization = "pwc-boeing-test_devops"

    workspaces {
      name = "datastage-migration-dev"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "dev | staging | prod"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project identifier used in all resource names"
  type        = string
  default     = "datastage-migration"
}

resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.project}-${var.environment}-datalake"

  tags = {
    Name        = "${var.project}-${var.environment}-datalake"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "databricks_role" {
  name = "${var.project}-${var.environment}-databricks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy" "databricks_s3_access" {
  name = "databricks-s3-access"
  role = aws_iam_role.databricks_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.data_lake.arn,
        "${aws_s3_bucket.data_lake.arn}/*"
      ]
    }]
  })
}

output "data_lake_bucket" {
  description = "S3 bucket name for the data lake"
  value       = aws_s3_bucket.data_lake.bucket
}

output "databricks_role_arn" {
  description = "IAM role ARN for Databricks"
  value       = aws_iam_role.databricks_role.arn
}
