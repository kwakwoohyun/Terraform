################################################################################
# Flow Log
################################################################################
# Cloudwatch logs
resource "aws_cloudwatch_log_group" "flow_log" {
    name = "/aws/eks/${var.cluster_name}/flow-log"
    retention_in_days = 7
    kms_key_id = var.kms_key_arn

    tags = {
        Name = "/aws/eks/${var.cluster_name}/flow-log"
        Environment = var.environments
    }
}

data "aws_iam_policy_document" "flow_log_cloudwatch_assume_role" {
    statement {
        sid = "AWSVPCFlowLogsAssumeRole"
        effect = "Allow"
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["vpc-flow-logs.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "vpc_flow_log_cloudwatch" {
    name_prefix = var.cluster_name
    assume_role_policy = data.aws_iam_policy_document.flow_log_cloudwatch_assume_role.json

    tags = {
        Name = format("%s-%s", var.cluster_name, "flow-log-role")
        Environment = var.environments
    }
}

resource "aws_iam_role_policy_attachment" "vpc_flow_log_cloudwatch" {
    role       = aws_iam_role.vpc_flow_log_cloudwatch.name
    policy_arn = aws_iam_policy.vpc_flow_log_cloudwatch.arn
}

data "aws_iam_policy_document" "vpc_flow_log_cloudwatch" {
    statement {
        sid = "AWSVPCFlowLogsPushToCloudWatch"
        effect = "Allow"

        actions = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
        ]

        resources = ["*"]
    }
}

resource "aws_iam_policy" "vpc_flow_log_cloudwatch" {
    name_prefix = var.cluster_name
    policy      = data.aws_iam_policy_document.vpc_flow_log_cloudwatch.json
}

resource "aws_flow_log" "flow-log" {
    log_destination_type     = "cloud-watch-logs"
    log_destination          = aws_cloudwatch_log_group.flow_log.arn
    iam_role_arn             = aws_iam_role.vpc_flow_log_cloudwatch.arn
    traffic_type             = "ALL"
    vpc_id                   = var.vpc_id
    max_aggregation_interval = 60

    # log_destination_type = "s3"의 옵션
    # destination_options {
    #     file_format = "plain-text"
    #     hive_compatible_partitions = false
    #     per_hour_partition = false
    # }

    tags = {
        Name = format("%s-%s", var.cluster_name, "flow-log")
        Environment = var.environments
    }
}
