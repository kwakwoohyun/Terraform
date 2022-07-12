################################################################################
# aws-auth configmap
# Only EKS managed node groups automatically add roles to aws-auth configmap
# so we need to ensure fargate profiles and self-managed node roles are added
################################################################################
# 사용자 정보 ARN
data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
    name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
    name = var.cluster_name
}

################################################################################
# Windows System에서 적용
################################################################################
locals {
    aws_auth_configmap_yaml = <<-EOT
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${var.nodegroup_role_arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${var.fargate_profile_arn}
      username: system:node:{{SessionName}}
      groups:
        - system:bootstrappers
        - system:nodes
        - system:node-proxier
EOT
}

data "template_file" "kubeconfig" {
    template = file("${path.module}/template/kubeconfig.tpl")

    vars = {
        kubeconfig_name = "terraform"
        cluster_name = data.aws_eks_cluster.cluster.name
        endpoint = data.aws_eks_cluster.cluster.endpoint
        cluster_auth_base64 = data.aws_eks_cluster.cluster.certificate_authority[0].data
        nodegroup_role_arn = var.nodegroup_role_arn
        fargate_profile_arn = var.fargate_profile_arn
    }
}

resource "local_file" "kubeconfig" {
    content  = data.template_file.kubeconfig.rendered
    filename = pathexpand("~/.kube/config")
}

resource "null_resource" "patch" {
    triggers = {
        cmd_patch  = "kubectl patch configmap/aws-auth --patch \"${local.aws_auth_configmap_yaml}\" -n kube-system"
    }

    provisioner "local-exec" {
        interpreter = ["PowerShell", "-Command"]
        command = self.triggers.cmd_patch
    }

    depends_on = [local_file.kubeconfig]
}

# resource "null_resource" "update-kube-config" {
# 	provisioner "local-exec" {
# 		command = "aws eks update-kubeconfig --name ${data.aws_eks_cluster.cluster.id}"
# 	}
# }

################################################################################
# Linux System에서 적용
################################################################################
# locals {
#     kubeconfig = yamlencode({
#         apiVersion      = "v1"
#         kind            = "Config"
#         current-context = "terraform"
#         clusters = [{
#             name = var.cluster_name
#             cluster = {
#                 certificate-authority-data = data.aws_eks_cluster.cluster.certificate_authority[0].data
#                 server                     = data.aws_eks_cluster.cluster.endpoint
#             }
#         }]
#         contexts = [{
#             name = "terraform"
#             context = {
#                 cluster = var.cluster_name
#                 user    = "terraform"
#             }
#         }]
#         users = [{
#             name = "terraform"
#             user = {
#                 token = data.aws_eks_cluster_auth.cluster.token
#             }
#         }]
#     })

#     aws_auth_configmap_yaml = <<-EOT
# apiVersion: v1
# kind: ConfigMap
# metadata:
#   name: aws-auth
#   namespace: kube-system
# data:
#   mapRoles: |
#     - rolearn: ${var.nodegroup_role_arn}
#       username: system:node:{{EC2PrivateDNSName}}
#       groups:
#         - system:bootstrappers
#         - system:nodes
#     - rolearn: ${var.fargate_profile_arn}
#       username: system:node:{{SessionName}}
#       groups:
#         - system:bootstrappers
#         - system:nodes
#         - system:node-proxier
# EOT
# }

# resource "null_resource" "patch" {
#     triggers = {
#         kubeconfig = base64encode(local.kubeconfig)
#         cmd_patch  = "kubectl patch configmap/aws-auth --patch \"${local.aws_auth_configmap_yaml}\" -n kube-system --kubeconfig <(echo $KUBECONFIG | base64 --decode)"
#     }

#     provisioner "local-exec" {
#         interpreter = ["/bin/bash", "-c"]
#         environment = {
#             KUBECONFIG = self.triggers.kubeconfig
#         }
#         command = self.triggers.cmd_patch
#     }
# }
