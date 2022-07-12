###############################################################
# Terraform provider defined
###############################################################
# Configure the terraform version
terraform {
    required_version = "~> 1.1"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.0"
        }
        null = {
            source  = "hashicorp/null"
            version = "~> 3.1"
        }
        tls = {
            source  = "hashicorp/tls"
            version = "~> 3.1"
        }
    }
}

# Configure the aws provider
provider "aws" {
    # shared_credentials_file옵션은 4.0 버전부터 사용되지 않음
    # shared_credentials_file = "$HOME/.aws/credentials"
    region = var.aws_region
}

# Configure the kubernetes provider
provider "kubernetes" {
    host = module.cluster.endpoint
    cluster_ca_certificate = base64decode(module.cluster.kubeconfig-certificate-authority-data)
    exec {
        api_version = "client.authentication.k8s.io/v1alpha1"
        args = ["eks", "get-token", "--cluster-name", module.cluster.cluster_name]
        command = "aws"
    }
}

###############################################################
# Local Variables
###############################################################
locals {
    svr_name = format("%s-%s", var.svr_name, var.environments == "prod" ? "" : var.environments)
    cluster_name = format("%s-%s-%s", var.svr_name, var.environments, "cluster")
}

data "aws_caller_identity" "current" {}

# AWS KMS KEY
resource "aws_kms_key" "eks" {
    description = "EKS Secret Encryption Key"
    deletion_window_in_days = 7
    enable_key_rotation = true
    policy = <<EOF
{
  "Version" : "2012-10-17",
  "Id" : "key-default-1",
  "Statement" : [ {
      "Sid" : "Enable IAM User Permissions",
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action" : "kms:*",
      "Resource" : "*"
    },
    {
      "Effect": "Allow",
      "Principal": { "Service": "logs.${var.aws_region}.amazonaws.com" },
      "Action": [ 
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*"
    }  
  ]
}
EOF

    tags = {
        Name = format("%s-%s", local.cluster_name, "kms")
        Environment = var.environments
    }
}

###############################################################
# Virtual Module Build
###############################################################
module "vpc" {
    source = "../../../modules/services/virtual/vpc"

    # service names
    svr_name = local.svr_name           # webapps-dev
    environments = var.environments     # dev
    cluster_name = local.cluster_name   # webapps-dev-cluster

    # cidr blocks
    cidr_block = var.cidr_block
}

module "subnet" {
    source = "../../../modules/services/virtual/subnet"

    # service names
    svr_name = local.svr_name           # webapps-dev
    environments = var.environments     # dev
    cluster_name = local.cluster_name   # webapps-dev-cluster

    # cidr blocks
    vpc_id = module.vpc.vpc_id
    subnets = var.subnets

    depends_on = [module.vpc]
}

###############################################################
# Network Module Build
###############################################################
module "gateway" {
    source = "../../../modules/services/network/gateway"

    # service names
    svr_name = local.svr_name           # webapps-dev
    environments = var.environments     # dev

    # create vpc id
    vpc_id = module.vpc.vpc_id

    # create public subnet ids
    public_subnet_ids = module.subnet.public_subnet_ids

    depends_on = [module.subnet]
}

module "route" {
    source = "../../../modules/services/network/route"

    # service names
    svr_name = local.svr_name           # webapps-dev
    environments = var.environments     # dev

    # create vpc id
    vpc_id = module.vpc.vpc_id

    # gateway ids
    gateway_id = module.gateway.gateway_id
    nat_ids = module.gateway.nat_ids

    # create subnet ids
    public_subnet_ids = module.subnet.public_subnet_ids
    private_subnet_ids = module.subnet.private_subnet_ids
    rds_subnet_ids = module.subnet.rds_subnet_ids
    
    depends_on = [module.gateway]
}

###############################################################
# Instance Module Build
###############################################################
module "security" {
    source = "../../../modules/services/instance/security"

    # service names
    svr_name = local.svr_name           # webapps-dev
    environments = var.environments     # dev
    cluster_name = local.cluster_name

    # create vpc id
    vpc_id = module.vpc.vpc_id

    # use port infos
    ports = var.ports

    depends_on = [module.route]
}

module "flowlog" {
    source = "../../../modules/services/instance/flowlog"

    # service names
    svr_name = local.svr_name           # webapps-dev
    environments = var.environments     # dev
    cluster_name = local.cluster_name
    
    # create vpc id
    vpc_id = module.vpc.vpc_id

    # kms key arn
    kms_key_arn = aws_kms_key.eks.arn

    depends_on = [module.security]
}

module "bastion" {
    source = "../../../modules/services/instance/bastion"

    # service names
    svr_name = local.svr_name           # webapps-dev
    environments = var.environments     # dev
    
    # create subnet ids
    public_subnet_ids = module.subnet.public_subnet_ids

    # instance infos
    ami = var.ami["bastion"]
    instance_type = var.instance_type["bastion"]
    bastion_security_group_id = module.security.bastion_security_group_id

    depends_on = [module.flowlog]
}

###############################################################
# Database Build
###############################################################
module "postgres" {
    source = "../../../modules/database/postgres"

    # service names
    svr_name = local.svr_name           # webapps-dev
    environments = var.environments     # dev

    rds_subnet_ids = module.subnet.rds_subnet_ids
    db_name = var.db_name
    db_instance_type = var.instance_type["database"]
    security_group_id = module.security.rds_security_group_id

    depends_on = [module.security]
}

###############################################################
# EKS Module Build
###############################################################
# cluster
module "cluster" {
    source = "../../../cluster/eks/fargate/cluster"

    # service names
    svr_name = local.svr_name           # webapps-dev
    environments = var.environments         # dev
    cluster_name = local.cluster_name       # webapps-dev-cluster
    cluster_version = var.cluster_version # 1.21

    # aws_eks_cluster
    cluster_security_group_id = module.security.cluster_security_group_id
    public_subnet_ids = module.subnet.public_subnet_ids
    private_subnet_ids = module.subnet.private_subnet_ids

    # kms key arn
    kms_key_arn = aws_kms_key.eks.arn
    
    depends_on = [module.bastion]
}

# node group
module "nodegroup" {
    source = "../../../cluster/eks/fargate/nodegroup"

    # service names
    environments = var.environments     # dev
    cluster_name = local.cluster_name   # webapps-dev-cluster

    # node security group id
    node_security_group_id = module.security.node_security_group_id

    # node instance profile
    instance_type = var.instance_type["instance"]
    key_name = module.bastion.key_name
    min_size = var.min_size
    max_size = var.max_size

    # aws_eks_cluster
    private_subnet_ids = module.subnet.private_subnet_ids

    depends_on = [module.cluster]
}

# fargate profile
module "profile" {
    source = "../../../cluster/eks/fargate/profile"

    # service names
    svr_name = local.svr_name           # webapps-dev
    environments = var.environments     # dev
    cluster_name = local.cluster_name   # webapps-dev-cluster

    # aws_eks_cluster
    private_subnet_ids = module.subnet.private_subnet_ids
    
    depends_on = [module.nodegroup]
}

# cluster config
module "config" {
    source = "../../../cluster/eks/fargate/config"

    # service names
    svr_name = local.svr_name           # webapps-dev
    environments = var.environments     # dev
    cluster_name = local.cluster_name   # webapps-dev-cluster
    
    # cluster info
    nodegroup_role_arn = module.nodegroup.nodegroup_role_arn
    fargate_profile_arn = module.profile.fargate_profile_arn
    
    depends_on = [module.profile]
}

# cluster config
module "addon" {
    source = "../../../cluster/eks/fargate/addon"

    # service names
    environments = var.environments     # dev
    cluster_name = local.cluster_name   # webapps-dev-cluster
    
    # cluster info
    cluster_oidc_issuer = module.cluster.cluster_oidc_issuer
    
    depends_on = [module.config]
}

###############################################################
# Application Deployment
###############################################################
# module "deploy" {
#     source = "../../../cluster/k8s"

#     aws_region = var.aws_region

#     # service names
#     svr_name = local.svr_name           # webapps-dev
#     environments = var.environments     # dev
#     cluster_name = local.cluster_name   # webapps-dev-cluster

#     # vpc_id
#     vpc_id = module.vpc.vpc_id
    
#     depends_on = [module.profile]
# }

###############################################################
# Additional Module
###############################################################
module "ecr" {
    source = "../../../modules/addition/ecr"

    cluster_name = local.cluster_name

    depends_on = [module.profile]
}

# static s3 저장소
module "statics" {
    source = "../../../modules/addition/statics/s3"

    # service names
    svr_name = local.svr_name           # webapps-dev
    environments = var.environments     # dev
    domain_name = var.domain_name

    # page 정보
    index_document = var.index_document
    error_document = var.error_document
    s3_force_destroy = var.s3_force_destroy

    depends_on = [module.ecr]
}

# static cloudfront
module "cloudfront" {
    source = "../../../modules/addition/statics/cloudfront"

    # service names
    svr_name = local.svr_name           # webapps-dev
    domain_name = var.domain_name

    # s3 정보
    endpoint = module.statics.bucket_domain_name
    index_document = var.index_document

    # CF인증요청 처리 key string
    secret_user_agent = var.secret_user_agent

    depends_on = [module.statics]
}

###################################################################################
# Terraform state
###################################################################################
# 변수를 사용하지 못하며 문자열만 사용가능 (${} 과 같은 변수입력 불가)
terraform {
    backend "s3" {
        bucket = "webapps-state-storage"
        key = "common/services/dev/terraform.tfstate"
        region = "ap-northeast-2"

        dynamodb_table = "webapps-state-locks"
        encrypt = true
    }
}