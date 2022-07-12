###################################################################################
# S3 bucket name = webapps-state-storage
# Dynamodb table name = webapps-state-locks
#----------------------------------------------------------------------------------
# Terraform provider defined :: terraform 0.13 and later
###################################################################################
# Configure the terraform version
terraform {
    required_version = ">= 1.1"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
}

# Configure the aws provider
provider "aws" {
    region = var.aws_region
}

###################################################################################
# Terraform State Storage :: Use s3 bucket and dynamodb table
###################################################################################
# 테라폼 상태관리 저장소로 S3 사용
resource "aws_s3_bucket" "storage" {
    bucket = format("%s-%s", var.bucket_name, "state-storage")

    # s3 bucket을 삭제하지 못하도록 설정
    # 삭제할때는 s3 bucket을 비우고, 주석처리한 다음 destroy 수행
    lifecycle {
        prevent_destroy = true
    }
}

# s3 저장소 acl
resource "aws_s3_bucket_acl" "storage" {
    bucket = aws_s3_bucket.storage.id
    acl = "private"
}

# s3 versioning
resource "aws_s3_bucket_versioning" "storage" {
    bucket = aws_s3_bucket.storage.id
    versioning_configuration {
        status = "Enabled"
    }
}

# s3 서버측 암호화 활성화
resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
    bucket = aws_s3_bucket.storage.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

# s3 저장소 lifecycle 설정
resource "aws_s3_bucket_lifecycle_configuration" "storage" {
    bucket = aws_s3_bucket.storage.id

    rule {
        id = "backups"
        status = "Enabled"

        filter {
            prefix = "backups/"
        }

        transition {
            days = 90
            storage_class = "GLACIER_IR"
        }

        transition {
            days = 180
            storage_class = "DEEP_ARCHIVE"
        }

        expiration {
            days = 365
        }
    }
}

# 테라폼에서 다이나모DB를 잠금에 사용
resource "aws_dynamodb_table" "locks" {
    name = format("%s-%s", var.bucket_name, "state-locks")
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
}

###################################################################################
# 주어진 Key값으로 상태정보를 저장 :: terraform init
# 삭제할 때는 terraform init --migrate-state 수행하고 주석처리한 다음 destroy
###################################################################################
# 변수를 사용하지 못하며 문자열만 사용가능 (${} 과 같은 변수입력 불가)
terraform {
    backend "s3" {
        bucket = "webapps-state-storage"
        key = "common/stores/s3/terraform.tfstate"
        region = "ap-northeast-2"

        dynamodb_table = "webapps-state-locks"
        encrypt = true
    }
}
