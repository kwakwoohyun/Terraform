###############################################################
# Security Group IDs
###############################################################
# The Bastion Host Security Group ID
output "bastion_security_group_id" {
    value = aws_security_group.bastion.id
}

# The Cluster Security Group ID
output "cluster_security_group_id" {
    value = aws_security_group.cluster.id
}

# The Worker Node Security Group ID
output "node_security_group_id" {
    value = aws_security_group.node.id
}

# The DB Security Group ID
output "rds_security_group_id" {
    value = aws_security_group.rds.id
}
