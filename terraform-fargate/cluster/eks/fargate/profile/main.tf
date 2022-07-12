########################################################################
# Fargate profile 등록
########################################################################
# cluster info search
data "aws_eks_cluster" "cluster" {
    name = var.cluster_name
}

resource "aws_eks_fargate_profile" "cluster" {
    cluster_name = var.cluster_name
    fargate_profile_name = format("%s-%s", var.cluster_name, "profile")
    pod_execution_role_arn = aws_iam_role.fargate.arn
    subnet_ids = var.private_subnet_ids

    selector {
        namespace = "default"
        labels = {
            WorkerType = "fargate"
        }
    }

    selector {
        namespace = var.svr_name
        labels = {
            Application = "nginx"
        }
    }

    timeouts {
        create = "30m"
        delete = "30m"
    }

    lifecycle {
        create_before_destroy = true
    }
    
    depends_on = [
        aws_iam_role_policy_attachment.fargate
    ]
}

###################################################################################
# IAM Role 생성 (Fargate)
###################################################################################
data "aws_iam_policy_document" "fargate" {
    statement {
        effect = "Allow"
        actions = ["sts:AssumeRole"]

        principals {
            type = "Service"
            identifiers = [
                "eks-fargate-pods.amazonaws.com"
            ]
        }
    }
}

resource "aws_iam_role" "fargate" {
    name = format("%s-%s", var.cluster_name, "fargate")
    force_detach_policies = true
    assume_role_policy = data.aws_iam_policy_document.fargate.json
}

# Amazon Policy
resource "aws_iam_role_policy_attachment" "fargate" {
    for_each = toset([
        "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy",
        "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
    ])
    
    policy_arn = each.value
    role = aws_iam_role.fargate.name
}
