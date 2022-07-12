terraform {
  required_version = ">= 1.2.4"

  required_providers {
    aws = {
      version = ">= 4.0.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

###################################################################################
# Terraform State Storage :: Use s3 bucket and dynamodb table
###################################################################################

###################################################################################
# 테라폼 상태관리 저장소로 S3 사용
###################################################################################
resource "aws_s3_bucket" "s3" {
  bucket = format("%s-%s", var.s3_bucket_name, "state-storage")

  # S3 bucket을 destroy로 삭제하지 못하도록 설정
  # 삭제하려면 S3 bucket을 비우고, false로 변경 후 destroy
  force_destroy = false
}

resource "aws_s3_bucket_acl" "s3_acl" {
  bucket = aws_s3_bucket.s3.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
  bucket = aws_s3_bucket.s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

###################################################################################
# 테라폼 상태관리 저장소로 DynamoDB 사용
###################################################################################
resource "aws_dynamodb_table" "dynamodb" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
