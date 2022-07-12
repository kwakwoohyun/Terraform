# AWS Identity
data "aws_caller_identity" "current" {}

########################################################################
# EKS Cluster 생성
########################################################################
resource "aws_eks_cluster" "cluster" {
    name = var.cluster_name
    role_arn = aws_iam_role.cluster.arn
    version = var.cluster_version
    enabled_cluster_log_types = ["api","audit","authenticator","controllerManager","scheduler"]

    vpc_config {
        security_group_ids = [var.cluster_security_group_id]
        subnet_ids = concat(var.public_subnet_ids, var.private_subnet_ids)

        endpoint_private_access = true
        endpoint_public_access = true
        public_access_cidrs = ["0.0.0.0/0"]
    }

    encryption_config {
        provider {
            key_arn = var.kms_key_arn
        }
        resources = ["secrets"]
    }

    timeouts {
        create = "30m"
        delete = "30m"
        update = "30m"
    }
    
    tags = {
        Name = var.cluster_name
        Environment = var.environments
    }

    depends_on = [
        aws_cloudwatch_log_group.cluster,
        aws_iam_role_policy_attachment.cluster
    ]
}

################################################################################
# IRSA - this is different from EKS identity provider
################################################################################
data "tls_certificate" "oidc" {
    url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
    client_id_list  = ["sts.amazonaws.com"]
    thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
    url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer

    tags = {
        Name = format("%s-%s", var.cluster_name, "irsa")
        Environment = var.environments
    }
}

###################################################################################
# EKS Cluster Role
###################################################################################
# eks assume role policy document
data "aws_iam_policy_document" "cluster" {
    statement {
        sid = "EKSClusterAssumeRole"
        actions = ["sts:AssumeRole"]

        principals {
            type = "Service"
            identifiers = ["eks.amazonaws.com"]
        }
    }
}

# IAM Role
resource "aws_iam_role" "cluster" {
    name = format("%s-%s", var.cluster_name, "role")
    force_detach_policies = true
    assume_role_policy = data.aws_iam_policy_document.cluster.json

    tags = {
        Name = format("%s-%s", var.cluster_name, "role")
        Environment = var.environments
    }
}

# Amazon Policy
resource "aws_iam_role_policy_attachment" "cluster" {
    for_each = toset([
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
        "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
        "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    ])
    
    policy_arn = each.value
    role = aws_iam_role.cluster.name
}


########################################################################
# CloudWatch 생성
########################################################################
resource "aws_cloudwatch_log_group" "cluster" {
    name = "/aws/eks/${var.cluster_name}/cluster"
    retention_in_days = 7
    kms_key_id = var.kms_key_arn

    tags = {
        Name = format("%s-%s", var.cluster_name, "log")
        Environments = var.environments
    }
}

########################################################################
# Namespace 등록 :: k8s에서 사용
########################################################################
resource "kubernetes_namespace" "webapps" {
    metadata {
        annotations = {
            name = var.svr_name
        }
        name = var.svr_name
    }
}