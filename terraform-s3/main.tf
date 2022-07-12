provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_s3_bucket" "terraform_state" {
  # 버킷이름
  bucket = "wkwak-terraform-up-and-running-state"

  # 실수로 버킷을 삭제하는 것을 방지
  lifecycle {
    # create_before_destroy 설정에 이은 두번째 수명주기
    # true로 설정하면 terraform_destroy를 실행하는것 같이 리소스를 삭제하려고 시도할 경우
    # 테라폼이 오류와 함께 종료됨
    prevent_destroy = true
  }

  # 코드 이력을 관리하기 위해 상태 파일의 버전 관리를 활성화
  versioning {
    enabled = true
  }

  # 서버측 암호화 활성화
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  name         = "wkwak-terraform-up-and-running-locks"
  attribute {
    name = "LockID"
    type = "S"
  }
}

terraform {
  backend "s3" {
    bucket = "wkwak-terraform-up-and-running-state"
    # 테라폼 상태 파일을 저장할 S3 버킷 내의 파일 경로
    key    = "global/s3/terraform.tfstate"
    region = "ap-northeast-2"

    # 잠금에 사용할 DynamoDB 테이블
    dynamodb_table = "wkwak-terraform-up-and-running-locks"
    # encrypt = true 설정시 테라폼 상태가 S3 디스크에 저장될 때 암호화된다.
    encrypt        = true
  }
}

# S3 버킷의 ARN (아마존리소스이름) 출력
output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket"
}

# DynamoDB 테이블의 이름 출력
output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table"
}