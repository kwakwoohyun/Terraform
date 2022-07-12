###################################################################################
# Security Group :: Bastion Host
###################################################################################
# security group :: bastion host
resource "aws_security_group" "bastion" {
    name = format("%s-%s", var.svr_name, "bastion")
    vpc_id = var.vpc_id

    tags = {
        Name = format("%s-%s", var.svr_name, "bastion")
        Environments = var.environments
    }
}

# security group rule :: inbound
resource "aws_security_group_rule" "bastion_ingress_ssh" {
    type = "ingress"
    security_group_id = aws_security_group.bastion.id

    from_port = var.ports.ssh_port
    to_port = var.ports.ssh_port
    protocol = var.ports.tcp_protocol
    cidr_blocks = var.ports.all_ips
}

# security group rule :: outbound
resource "aws_security_group_rule" "bastion_egress_all" {
    type = "egress"
    security_group_id = aws_security_group.bastion.id

    from_port = var.ports.any_port
    to_port = var.ports.any_port
    protocol = var.ports.any_protocol
    cidr_blocks = var.ports.all_ips
}

###################################################################################
# Security Group :: EKS Cluster
# 참조URL) https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
###################################################################################
# Security Group
resource "aws_security_group" "cluster" {
    name = format("%s-%s", var.svr_name, "cluster")
    vpc_id = var.vpc_id
	
    tags = {
        Name = format("%s-%s", var.svr_name, "cluster")
        Environments = var.environments
    }
}

# Security Group Rule :: Node Inbound
resource "aws_security_group_rule" "cluster_https_ingress_node" {
    type = "ingress"
    security_group_id = aws_security_group.cluster.id
    source_security_group_id = aws_security_group.node.id

    from_port = var.ports.https_port    # 443
    to_port = var.ports.https_port      # 443
    protocol = var.ports.tcp_protocol
}

# Security Group Rule :: ALL outbound
resource "aws_security_group_rule" "cluster_egress_all" {
    type = "egress"
    security_group_id = aws_security_group.cluster.id

    from_port = var.ports.any_port
    to_port = var.ports.any_port
    protocol = var.ports.any_protocol
    cidr_blocks = var.ports.all_ips
}

###################################################################################
# Security Group :: EKS Worker Nodes
# 참조URL) https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
###################################################################################
# Security Group
resource "aws_security_group" "node" {
    name = format("%s-%s", var.svr_name, "node")
    vpc_id = var.vpc_id
	
    tags = {
        Name = format("%s-%s", var.svr_name, "node")
        Environments = var.environments
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
}

# Security Group Rule :: SSH Inbound
resource "aws_security_group_rule" "node_ssh_ingress_bastion" {
    type = "ingress"
    security_group_id = aws_security_group.node.id
    source_security_group_id = aws_security_group.bastion.id

    from_port = var.ports.ssh_port    # 22
    to_port = var.ports.ssh_port      # 22
    protocol = var.ports.tcp_protocol
}

# Security Group Rule :: Node Inbound
resource "aws_security_group_rule" "node_https_ingress_cluster" {
    type = "ingress"
    security_group_id = aws_security_group.node.id
    source_security_group_id = aws_security_group.cluster.id

    from_port = var.ports.https_port    # 443
    to_port = var.ports.https_port      # 443
    protocol = var.ports.tcp_protocol
}

# Security Group Rule :: Self Inbound
resource "aws_security_group_rule" "node_ingress_self" {
    type = "ingress"
    security_group_id = aws_security_group.node.id
    source_security_group_id = aws_security_group.node.id

    from_port = var.ports.any_port      # 0
    to_port = var.ports.node_to_port    # 65535
    protocol = var.ports.any_protocol
}

# Security Group Rule :: Cluster Inbound
resource "aws_security_group_rule" "node_ingress_cluster" {
    type = "ingress"
    security_group_id = aws_security_group.node.id
    source_security_group_id = aws_security_group.cluster.id

    from_port = var.ports.node_from_port    # 1025
    to_port = var.ports.node_to_port        # 65535
    protocol = var.ports.tcp_protocol
}

# Security Group Rule :: ALL outbound
resource "aws_security_group_rule" "node_egress_all" {
    type = "egress"
    security_group_id = aws_security_group.node.id

    from_port = var.ports.any_port
    to_port = var.ports.any_port
    protocol = var.ports.any_protocol
    cidr_blocks = var.ports.all_ips
}

###################################################################################
# Security Group :: Database
###################################################################################
# Security Group
resource "aws_security_group" "rds" {
    name = format("%s-%s", var.svr_name, "rds")
    vpc_id = var.vpc_id
	
    tags = {
        Name = format("%s-%s", var.svr_name, "rds")
        Environments = var.environments
    }
}

# Security Group Rule :: SSH Inbound
resource "aws_security_group_rule" "rds_ingress_all" {
    type = "ingress"
    security_group_id = aws_security_group.rds.id

    from_port = var.ports.db_port
    to_port = var.ports.db_port
    protocol = var.ports.tcp_protocol
    cidr_blocks = var.ports.all_ips
}

# Security Group Rule :: SSH Inbound
resource "aws_security_group_rule" "rds_ssh_ingress_all" {
    type = "ingress"
    security_group_id = aws_security_group.rds.id

    from_port = var.ports.ssh_port
    to_port = var.ports.ssh_port
    protocol = var.ports.tcp_protocol
    cidr_blocks = var.ports.all_ips
}

# Security Group Rule :: ALL outbound
resource "aws_security_group_rule" "rds_egress_all" {
    type = "egress"
    security_group_id = aws_security_group.rds.id

    from_port = var.ports.any_port
    to_port = var.ports.any_port
    protocol = var.ports.any_protocol
    cidr_blocks = var.ports.all_ips
}
