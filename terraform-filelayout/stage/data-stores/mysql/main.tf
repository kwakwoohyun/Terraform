provider "aws" {
  region = "ap-northeast-2"
}

#############################################################
# Secret Manager
#############################################################
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}
# Creating a AWS secret for database master account (Masteraccoundb)
resource "aws_secretsmanager_secret" "db_password" {
  name = "wkwak-terraform-rds-mysql"
}
# Creating a AWS secret versions for database master account (Masteraccoundb)
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.password.result
}
# Importing the AWS secrets created previously using arn.
data "aws_secretsmanager_secret" "db_password" {
  arn = aws_secretsmanager_secret.db_password.arn
}
# Importing the AWS secret version created previously using arn.
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}
# After importing the secrets storing into Locals
locals {
  db_creds = data.aws_secretsmanager_secret_version.db_password.secret_string
}

#############################################################
# Mysql RDS
#############################################################
resource "aws_db_instance" "example" {
  identifier_prefix = "wkwak-terraform-up-and-running"
  engine            = "mysql"
  allocated_storage = "10"
  instance_class    = "db.t2.micro"
  name              = "wkwak_example_database"
  username          = "admin"
  password          = local.db_creds

  skip_final_snapshot = true
}

#############################################################
# backend
#############################################################
terraform {
  backend "s3" {
    bucket = "wkwak-terraform-up-and-running-state"
    # 테라폼 상태 파일을 저장할 S3 버킷 내의 파일 경로
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "ap-northeast-2"

    # 잠금에 사용할 DynamoDB 테이블
    dynamodb_table = "wkwak-terraform-up-and-running-locks"
    # encrypt = true 설정시 테라폼 상태가 S3 디스크에 저장될 때 암호화된다.
    encrypt = true
  }
}