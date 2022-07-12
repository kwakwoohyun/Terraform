provider "aws" {
  region = "ap-northeast-2"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "wkwak-teraform-webservers-prod"
  instance_type = "m4.large"
  min_size = 2
  max_size = 3
}