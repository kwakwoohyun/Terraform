variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "s3_bucket_name" {
  type = string
}

variable "dynamodb_table_name" {
  type = string
}
