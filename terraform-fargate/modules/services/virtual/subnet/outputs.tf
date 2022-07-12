###############################################################
# Public Subnet IDS
###############################################################
output "public_subnet_ids" {
    value = [
        for az, subnet in aws_subnet.public: subnet.id
    ]
}

###############################################################
# Private Subnet IDS
###############################################################
output "private_subnet_ids" {
    value = [
        for az, subnet in aws_subnet.private: subnet.id
    ]
}

###############################################################
# Private Subnet IDS
###############################################################
output "rds_subnet_ids" {
    value = [
        for az, subnet in aws_subnet.rds: subnet.id
    ]
}
