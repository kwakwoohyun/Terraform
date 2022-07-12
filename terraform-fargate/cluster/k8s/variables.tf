###############################################################
# Basic info
###############################################################
# aws region :: seoul region
variable "aws_region" {
    type = string
    default = "ap-northeast-2"
}

# application service name
variable "svr_name" {
    type = string
    default = "webapps"
}

# environments :: dev, stage and prod
variable "environments" {
    type = string
    default = "dev"
}

###############################################################
# VPC IDs
###############################################################
# terraform apply -var vpc_id="created vpc id"
variable "vpc_id" {
    type = string
    default = "vpc-0c55135ca2d970508"
}

###############################################################
# EKS cluster issuer
###############################################################
variable "cluster_oidc_issuer" {
    type = string
    default = "https://oidc.eks.ap-northeast-2.amazonaws.com/id/14A1CC1F18E2554317235BA5D9F2635A"
}

###############################################################
# EKS cluster issuer
###############################################################
variable "oidc_arn" {
    type = string
    default = "arn:aws:iam::160270626841:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/14A1CC1F18E2554317235BA5D9F2635A"
}
