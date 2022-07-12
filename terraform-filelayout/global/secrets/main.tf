provider "aws" {
  region = "ap-northeast-2"
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

# Creating a AWS secret for database master account (Masteraccoundb)
resource "aws_secretsmanager_secret" "db_password" {
  name = "wkwak-terraform-mysql"
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