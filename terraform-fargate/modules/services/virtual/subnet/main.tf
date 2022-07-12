###################################################################################
# Public Subnet :: Bastion Host & NAT Gateway
###################################################################################
resource "aws_subnet" "public" {
    vpc_id = var.vpc_id

    for_each = var.subnets.public
    availability_zone = each.value
    cidr_block = each.key
    map_public_ip_on_launch = true
    
    tags = {
        Name = format("%s-%s", var.svr_name, "public${split(".", each.key)[2]}")
        Environments = var.environments
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        "kubernetes.io/role/elb" = 1    # external load balancer
    }
}

###################################################################################
# Private Subnet :: Worker Nodes & Database Nodes
###################################################################################
resource "aws_subnet" "private" {
    vpc_id = var.vpc_id

    for_each = var.subnets.private
    availability_zone = each.value
    cidr_block = each.key
    
    tags = {
        Name = format("%s-%s", var.svr_name, "private${substr(each.key, 10, 1)}")
        Environments = var.environments
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        "kubernetes.io/role/internal-elb" = 1   # internel load balancer
    }
}

###################################################################################
# Database Private Subnet
###################################################################################
resource "aws_subnet" "rds" {
    vpc_id = var.vpc_id

    for_each = var.subnets.rds
    availability_zone = each.value
    cidr_block = each.key
    
    tags = {
        Name = format("%s-%s", var.svr_name, "rds${substr(each.key, 10, 1)}")
        Environments = var.environments
    }
}