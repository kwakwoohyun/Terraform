# Configure the aws provider
provider "aws" {
  # shared_credentials_file옵션은 4.0 버전부터 사용되지 않음
  # shared_credentials_file = "$HOME/.aws/credentials"
  region = "ap-northeast-2"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = "wkwak-terraform-vpc-module-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2c"] #가용영역 지정
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]  #공개 서브넷
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"] #비공개 서브넷
  database_subnets = ["10.0.5.0/24", "10.0.6.0/24"] #데이터베이스 서브넷

  enable_nat_gateway = true			#NAT Gateway 활성
  single_nat_gateway = true         #단일 NAT Gateway 설정
  one_nat_gateway_per_az = false    #단일 NAT 설정 시 false로 비활성화

  create_database_subnet_group            = true    #RDS용 서브넷 구성
  create_database_subnet_route_table      = true    #RDS용 서브넷의 라우팅 테이블 구성
  create_database_internet_gateway_route  = true    #RDS용 라우팅 테이블에 인터넷 게이트웨이 연결 설정 여부

  enable_dns_hostnames = "true"  #DNS Hostname Enable
  enable_dns_support    = "true"   #DNS Support Enable

  tags = { "TerraformManaged" = "true" }
}