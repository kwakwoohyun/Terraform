provider "aws" {
  region = "ap-northeast-2"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "wkwak-teraform-webservers-stage"
  instance_type = "t2.micro"
  min_size = 1
  max_size = 2
}