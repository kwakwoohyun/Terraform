########################################################################
# EKS Cluster 생성
########################################################################
# Cloudwatch log 활성화
resource "aws_cloudwatch_log_group" "cluster" {
    # The log group name format is /aws/eks/<cluster-name>/cluster
    name = "/aws/eks/${var.cluster_name}/cluster"
    retention_in_days = 7

    tags = {
        Name = format("%s-%s", var.cluster_name, "log")
        Environments = var.environments
    }
}

# EKS cluster 생성
resource "aws_eks_cluster" "cluster" {
    name = var.cluster_name
    role_arn = var.cluster_role_arn

    vpc_config {
        security_group_ids = [var.cluster_security_group_id]
        subnet_ids = concat(var.public_subnet_ids, var.private_subnet_ids)

        endpoint_private_access = false
        endpoint_public_access = true
    }

    # cloudwatch log 활성화
    enabled_cluster_log_types = ["api","audit","authenticator","controllerManager","scheduler"]

    depends_on = [
        aws_cloudwatch_log_group.cluster
    ]
}

########################################################################
# EKS Worker Nodes Template
########################################################################
data "aws_ami" "eks-worker" {
    filter {
        name = "name"
        values = ["amazon-eks-node-${aws_eks_cluster.cluster.version}-v*"]
    }
    most_recent = true
    owners = ["602401143452"] # Amazon EKS AMI Account ID
}

# User Data (Kube Config)
locals {
    kubeconfig_data = {
        CLUSTER_NAME = aws_eks_cluster.cluster.name
        B64_CLUSTER_CA = aws_eks_cluster.cluster.certificate_authority.0.data
        API_SERVER_URL = aws_eks_cluster.cluster.endpoint
    }
}

# Aws launch configuration
resource "aws_launch_configuration" "worker" {
    associate_public_ip_address = false
    name_prefix = var.cluster_name
    iam_instance_profile = var.node_profile_name
    image_id = data.aws_ami.eks-worker.id
    instance_type = var.instance_type
    
    key_name = var.key_name
    
    security_groups = [var.node_security_group_id]

    user_data_base64 = base64encode(templatefile("${path.module}/template/userdata.tpl", local.kubeconfig_data))

    lifecycle {
        create_before_destroy = true
    }
}

###################################################################################
# Kubectl Config File Update
###################################################################################
resource "null_resource" "update-kube-config" {
	provisioner "local-exec" {
		command = "aws eks update-kubeconfig --name ${aws_eks_cluster.cluster.id}"
	}
	depends_on = [aws_launch_configuration.worker]
}

###################################################################################
# AWS AUTH
###################################################################################
# 사용자 정보 ARN
data "aws_iam_user" "current" {
    user_name = var.user_name
}

# kubernetes config map :: aws_auth
resource "kubernetes_config_map" "aws-auth-configmap" {
	metadata {
		name = "aws-auth"
		namespace = "kube-system"
        labels = merge(
            {
                "app.kubernetes.io/managed-by" = "Terraform"
                "terraform.io/module" = "terraform-aws-modules.eks.aws"
            }
        )
	}
	data = {
        api_host = aws_eks_cluster.cluster.endpoint
        mapRoles =<<YAML
- groups:
  - system:bootstrappers
  - system:nodes
  rolearn: ${var.node_role_arn}
  username: system:node:{{EC2PrivateDNSName}}
YAML
        mapUsers =<<YAML
- userarn: ${data.aws_iam_user.current.arn}
  username: ${data.aws_iam_user.current.id}
  groups:
    - system:masters
YAML
	}

    depends_on = [null_resource.update-kube-config]
}

########################################################################
# EKS Worker Nodes
########################################################################
resource "aws_autoscaling_group" "worker" {
    name = format("%s-%s", var.cluster_name, "asg")
    
    launch_configuration = aws_launch_configuration.worker.id

    vpc_zone_identifier = var.private_subnet_ids

    desired_capacity = var.min_size
    max_size = var.max_size
    min_size = var.min_size

    # ASG 배포 완료를 고려하기 전에 최소 지정된 인스턴스가 상태 확인을 통과할 때까지 기다린다.
    min_elb_capacity = var.min_size
    
    tag {
        key = "Name"
        value = format("%s-%s", var.cluster_name, "asg")
        propagate_at_launch = true
    }

    tag {
        key = "kubernetes.io/cluster/${var.cluster_name}"
        value = "owned"
        propagate_at_launch = true
    }

    depends_on = [kubernetes_config_map.aws-auth-configmap]
}

########################################################################
# Autoscaling Schedule
########################################################################
# Autoscaling Schedule :: Start (업무시간에 확장처리)
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
    count = var.enable_autoscaling ? 1 : 0

    scheduled_action_name = "${var.cluster_name}-scale-out-during-business-hours"
    min_size = var.min_size
    max_size = var.max_size
    desired_capacity = var.max_size
    recurrence = "0 9 * * *"

    autoscaling_group_name = aws_autoscaling_group.worker.name

    depends_on = [aws_autoscaling_group.worker]
}

# Autoscaling Schedule :: End (업무종료시간에 축소처리)
resource "aws_autoscaling_schedule" "scale_in_at_night" {
    count = var.enable_autoscaling ? 1 : 0

    scheduled_action_name = "${var.cluster_name}-scale-in-at-night"
    min_size = var.min_size
    max_size = var.min_size
    desired_capacity = var.min_size
    recurrence = "0 17 * * *"

    autoscaling_group_name = aws_autoscaling_group.worker.name

    depends_on = [aws_autoscaling_group.worker]
}

########################################################################
# Cloudwatch Alarm
########################################################################
resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
    alarm_name  = format("%s-%s", var.cluster_name, "high-cpu-utilization")
    namespace   = "AWS/EC2"
    metric_name = "CPUUtilization"

    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.worker.name
    }

    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    period              = 300
    statistic           = "Average"
    threshold           = 90
    unit                = "Percent"

    depends_on = [aws_autoscaling_group.worker]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
    count = format("%.1s", var.instance_type) == "t" ? 1 : 0

    alarm_name  = format("%s-%s", var.cluster_name, "low-cpu-credit-balance")
    namespace   = "AWS/EC2"
    metric_name = "CPUCreditBalance"

    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.worker.name
    }

    comparison_operator = "LessThanThreshold"
    evaluation_periods  = 1
    period              = 300
    statistic           = "Minimum"
    threshold           = 10
    unit                = "Count"

    depends_on = [aws_autoscaling_group.worker]
}

# resource "aws_eks_node_group" "nodes_general" {
#   # Name of the EKS Cluster.
#   cluster_name = aws_eks_cluster.eks.name

#   # Name of the EKS Node Group.
#   node_group_name = "nodes-general"

#   # Amazon Resource Name (ARN) of the IAM Role that provides permissions for the EKS Node Group.
#   node_role_arn = aws_iam_role.nodes_general.arn

#   # Identifiers of EC2 Subnets to associate with the EKS Node Group. 
#   # These subnets must have the following resource tag: kubernetes.io/cluster/CLUSTER_NAME 
#   # (where CLUSTER_NAME is replaced with the name of the EKS Cluster).
#   subnet_ids = [
#     aws_subnet.private_1.id,
#     aws_subnet.private_2.id
#   ]

#   # Configuration block with scaling settings
#   scaling_config {
#     # Desired number of worker nodes.
#     desired_size = 1

#     # Maximum number of worker nodes.
#     max_size = 1

#     # Minimum number of worker nodes.
#     min_size = 1
#   }

#   # Type of Amazon Machine Image (AMI) associated with the EKS Node Group.
#   # Valid values: AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64
#   ami_type = "AL2_x86_64"

#   # Type of capacity associated with the EKS Node Group. 
#   # Valid values: ON_DEMAND, SPOT
#   capacity_type = "ON_DEMAND"

#   # Disk size in GiB for worker nodes
#   disk_size = 20

#   # Force version update if existing pods are unable to be drained due to a pod disruption budget issue.
#   force_update_version = false

#   # List of instance types associated with the EKS Node Group
#   instance_types = ["t3.small"]

#   labels = {
#     role = "nodes-general"
#   }

#   # Kubernetes version
#   version = "1.18"

#   # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
#   # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
#   depends_on = [
#     aws_iam_role_policy_attachment.amazon_eks_worker_node_policy_general,
#     aws_iam_role_policy_attachment.amazon_eks_cni_policy_general,
#     aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
#   ]
# }
