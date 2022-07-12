###################################################################################
# Locals Variables
###################################################################################
# cluster info search
data "aws_eks_cluster" "cluster" {
    name = var.cluster_name
}

data "aws_ami" "eks-worker" {
    filter {
        name = "name"
        values = ["amazon-eks-node-${data.aws_eks_cluster.cluster.version}-v*"]
    }
    most_recent = true
    owners = ["602401143452"] # Amazon EKS AMI Account ID
}

# User Data (Kube Config)
locals {
    kubeconfig_data = {
        CLUSTER_NAME = data.aws_eks_cluster.cluster.name
        B64_CLUSTER_CA = data.aws_eks_cluster.cluster.certificate_authority.0.data
        API_SERVER_URL = data.aws_eks_cluster.cluster.endpoint
    }
}

###################################################################################
# IAM ROLE
###################################################################################
# ec2 assume role policy document (위, bastion과 동일)
data "aws_iam_policy_document" "node" {
    statement {
        sid = "EKSNodeAssumeRole"
        actions = ["sts:AssumeRole"]

        principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

# IAM Role
resource "aws_iam_role" "node" {
    name = format("%s-%s", var.cluster_name, "node")
    force_detach_policies = true
    assume_role_policy = data.aws_iam_policy_document.node.json
}

# Amazon Policy
resource "aws_iam_role_policy_attachment" "node" {
    for_each = toset([
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    ])
    
    policy_arn = each.value
    role = aws_iam_role.node.name
}

resource "aws_iam_instance_profile" "node" {
	name = format("%s-%s", var.cluster_name, "node")
    role = aws_iam_role.node.name
}

########################################################################
# EKS Worker Nodes Template
########################################################################
# Aws launch template
resource "aws_launch_template" "node" {
    name_prefix = var.cluster_name

    block_device_mappings {
        device_name = "/dev/xvda"

        ebs {
            volume_size = 20
            volume_type = "gp2"
        }
    }

    credit_specification {
        cpu_credits = "standard"
    }

    ebs_optimized = true
    image_id = data.aws_ami.eks-worker.id
    instance_type = var.instance_type
    key_name = var.key_name
    vpc_security_group_ids = [var.node_security_group_id]

    user_data = base64encode(templatefile("${path.module}/template/userdata.tpl", local.kubeconfig_data))

    tag_specifications {
        resource_type = "instance"

        tags = {
            Name = format("%s-%s", var.cluster_name, "node-template")
        }
    }

    lifecycle {
        create_before_destroy = true
    }
}

########################################################################
# EKS Worker Nodes
########################################################################
resource "aws_eks_node_group" "node" {
    cluster_name = var.cluster_name
    node_group_name = format("%s-%s", var.cluster_name, "node")
    node_role_arn = aws_iam_role.node.arn
    subnet_ids = var.private_subnet_ids

    scaling_config {
        desired_size = var.min_size
        max_size = var.max_size
        min_size = var.min_size
    }

    launch_template {
        name = aws_launch_template.node.name
        version = aws_launch_template.node.latest_version
    }

    tags = {
        Name = format("%s-%s", var.cluster_name, "node")
        Environment = var.environments
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
        propagate_at_launch = true
    }

    depends_on = [
        aws_iam_role_policy_attachment.node
    ]
}
