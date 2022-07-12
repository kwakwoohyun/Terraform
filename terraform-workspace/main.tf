resource "aws_instance" "example" {
  ami           = "ami-0fd0765afb77bcca7"
  instance_type = "t2.micro"

  tags = {
    Name = "wkwak-terraform-instance"
  }
}

terraform {
  backend "s3" {
    bucket = "wkwak-terraform-up-and-running-state"
    key    = "workspaces-example/terraform.tfstate"
    region = "ap-northeast-2"

    dynamodb_table = "wkwak-terraform-up-and-running-locks"
    encrypt        = true
  }
}