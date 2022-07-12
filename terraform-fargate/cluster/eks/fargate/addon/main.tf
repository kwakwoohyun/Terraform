################################################################################
# EKS Addons
################################################################################
# VPC_CNI ADDON
resource "aws_eks_addon" "vpc_cni" {
    cluster_name      = var.cluster_name
    addon_name        = "vpc-cni"
    resolve_conflicts = "OVERWRITE"
    addon_version     = "v1.10.1-eksbuild.1"

    lifecycle {
        ignore_changes = [modified_at]
    }

    tags = {
        Name = format("%s-%s", var.cluster_name, "addon-cni")
        Environment = var.environments
    }
}

# KUBE_PROXY ADDON
resource "aws_eks_addon" "kube_proxy" {
    cluster_name      = var.cluster_name
    addon_name        = "kube-proxy"
    resolve_conflicts = "OVERWRITE"
    addon_version     = "v1.21.2-eksbuild.2"
    
    lifecycle {
        ignore_changes = [modified_at]
    }

    tags = {
        Name = format("%s-%s", var.cluster_name, "addon-proxy")
        Environment = var.environments
    }
}

# CORE_DNS ADDON
resource "aws_eks_addon" "coredns" {
    cluster_name      = var.cluster_name
    addon_name        = "coredns"
    resolve_conflicts = "OVERWRITE"
    addon_version     = "v1.8.4-eksbuild.1"
    
    lifecycle {
        ignore_changes = [modified_at]
    }

    tags = {
        Name = format("%s-%s", var.cluster_name, "addon-dns")
        Environment = var.environments
    }
}

################################################################################
# EKS Identity Provider - this is different from IRSA
################################################################################
resource "aws_eks_identity_provider_config" "this" {
    cluster_name = var.cluster_name

    oidc {
        client_id                     = "sts.amazonaws.com"
        groups_claim                  = "groups"
        groups_prefix                 = "oidc:"
        identity_provider_config_name = "REDACTED"
        issuer_url                    = var.cluster_oidc_issuer
    }

    tags = {
        Name = format("%s-%s", var.cluster_name, "config")
        Environments = var.environments
    }

    timeouts {
        create = "60m"
        delete = "60m"
    }
}
