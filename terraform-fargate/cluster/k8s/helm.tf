###############################################################
# Terraform provider defined
# ingress 강제삭제 :
#   kubectl patch ingress nginx-alb -n webapps-dev -p '{"metadata":{"finalizers":[]}}' --type=merge
###############################################################
# Configure the terraform version
terraform {
    required_version = ">= 0.13.1"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = ">= 3.64"
        }
        helm = {
            source  = "hashicorp/helm"
            version = ">= 2.2"
        }
    }
}

# Configure the aws provider
provider "aws" {
    region = var.aws_region
}

###############################################################
# Local Variables
###############################################################
locals {
    svr_name = format("%s-%s", var.svr_name, var.environments == "prod" ? "" : var.environments)
    cluster_name = format("%s-%s-%s", var.svr_name, var.environments, "cluster")
    kube_config = "~/.kube/config"
    alb_controller_helm_repo     = "https://aws.github.io/eks-charts"
    alb_controller_chart_name    = "aws-load-balancer-controller"
    alb_controller_chart_version = "1.3.3"  # chart version "1.3.3" is app version "v2.3.1"
}

###############################################################
# Data Initialization
###############################################################
# aws caller identity
data "aws_caller_identity" "current" {}

# Configure the kubernetes provider
data "aws_eks_cluster" "cluster" {
    name = local.cluster_name
}

# aws eks cluster auth
data "aws_eks_cluster_auth" "cluster" {
    name = local.cluster_name
}

provider "kubernetes" {
    host = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    exec {
        api_version = "client.authentication.k8s.io/v1alpha1"
        args = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
        command = "aws"
    }
}

provider "helm" {
    kubernetes {
        config_path = "~/.kube/config"
    }
}

###############################################################
# ALB controller service account
###############################################################
resource "kubernetes_service_account" "controller" {
    automount_service_account_token = true
    metadata {
        name = "aws-load-balancer-controller"
        namespace = "kube-system"
        annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.controller_role.arn
        }
        labels = {
            "app.kubernetes.io/name"       = "aws-load-balancer-controller"
            "app.kubernetes.io/component"  = "controller"
            "app.kubernetes.io/managed-by" = "terraform"
        }
    }

    depends_on = [
        aws_iam_role_policy_attachment.api_call,
        aws_iam_role_policy_attachment.api_access
    ]
}

###############################################################
# AWS alb cluster role
###############################################################
resource "kubernetes_cluster_role" "controller" {
    metadata {
        name = "aws-load-balancer-controller"

        labels = {
            "app.kubernetes.io/name"       = "aws-load-balancer-controller"
            "app.kubernetes.io/managed-by" = "terraform"
        }
    }

    rule {
        api_groups = ["","extensions",]
        resources = ["configmaps","endpoints","events","ingresses","ingresses/status","services",]
        verbs = ["create","get","list","update","watch","patch",]
    }

    rule {
        api_groups = ["","extensions",]
        resources = ["nodes","pods","secrets","services","namespaces",]
        verbs = ["get","list","watch",]
    }

    depends_on = [kubernetes_service_account.controller]
}

resource "kubernetes_cluster_role_binding" "controller" {
    metadata {
        name = "aws-load-balancer-controller"

        labels = {
            "app.kubernetes.io/name"       = "aws-load-balancer-controller"
            "app.kubernetes.io/managed-by" = "terraform"
        }
    }

    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind      = "ClusterRole"
        name      = kubernetes_cluster_role.controller.metadata[0].name
    }

    subject {
        api_group = ""
        kind      = "ServiceAccount"
        name      = kubernetes_service_account.controller.metadata[0].name
        namespace = kubernetes_service_account.controller.metadata[0].namespace
    }

    depends_on = [kubernetes_cluster_role.controller]
}

###############################################################
# Helm release
###############################################################
resource "helm_release" "alb_controller" {
    name       = local.alb_controller_chart_name
    repository = local.alb_controller_helm_repo
    chart      = local.alb_controller_chart_name
    version    = local.alb_controller_chart_version
    namespace  = "kube-system"
    atomic     = true
    timeout    = 900

    values = [
        yamlencode({
            "clusterName" : data.aws_eks_cluster.cluster.name,
            "serviceAccount" : {
                "create" : false,
                "name" : kubernetes_service_account.controller.metadata[0].name
            },
            "region" : var.aws_region,
            "vpcId" : var.vpc_id
        })
    ]

    depends_on = [kubernetes_service_account.controller]
}

###############################################################
# Fargate Deployment
###############################################################
resource "kubernetes_deployment" "app" {
    metadata {
        name = "nginx"
        namespace = local.svr_name
        labels = {
            app = "nginx"
        }
    }

    spec {
        replicas = 2

        selector {
            match_labels = {
                app = "nginx"
            }
        }

        template {
            metadata {
                labels = {
                    app = "nginx"
                }
            }

            spec {
                container {
                    image = "nginx:1.14.2"
                    name  = "nginx"

                    port {
                        container_port = 80
                    }
                }
            }
        }
    }

    depends_on = [helm_release.alb_controller]
}

###############################################################
# Fargate Service
###############################################################
resource "kubernetes_service" "app" {
    metadata {
        name = "nginx-service"
        namespace = local.svr_name
    }
    spec {
        selector = {
            app = kubernetes_deployment.app.metadata[0].labels.app
        }

        port {
            port        = 80
            target_port = 80
            protocol    = "TCP"
        }

        type = "NodePort"
    }

    depends_on = [kubernetes_deployment.app]
}

###############################################################
# ALB for WebApp
###############################################################
resource "kubernetes_ingress" "app" {
    metadata {
        name = "nginx-alb"
        namespace = local.svr_name
        annotations = {
            "kubernetes.io/ingress.class" = "alb"
            "alb.ingress.kubernetes.io/scheme" = "internet-facing"
            "alb.ingress.kubernetes.io/target-type" = "ip"
        }
        labels = {
            "app" = "nginx"
        }
    }

    spec {
        backend {
            service_name = "nginx-service"
            service_port = 80
        }
        rule {
            http {
                path {
                    path = "/"
                    backend {
                        service_name = kubernetes_service.app.metadata[0].name
                        service_port = kubernetes_service.app.spec[0].port[0].port
                    }
                }
            }
        }
    }

    depends_on = [kubernetes_service.app]
}
