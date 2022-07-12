###################################################################################
# Internet Gateway
###################################################################################
resource "aws_internet_gateway" "igw" {
    vpc_id = var.vpc_id

    tags = {
        Name = format("%s-%s", var.svr_name, "igw")
        Environments = var.environments
    }
}

###################################################################################
# NAT Gateway
###################################################################################
resource "aws_nat_gateway" "nat" {
    count = length(var.public_subnet_ids)

    allocation_id = element(aws_eip.eip.*.id, count.index)
    subnet_id = element(var.public_subnet_ids, count.index)

    tags = {
        Name = format("%s-%s", var.svr_name, "nat${count.index + 1}")
        Environments = var.environments
    }
}

###################################################################################
# EIP
###################################################################################
resource "aws_eip" "eip" {
    count = length(var.public_subnet_ids)
    vpc = true

    lifecycle {
        create_before_destroy = true
    }
    tags = {
        Name = format("%s-%s", var.svr_name, "eip${count.index + 1}")
        Environments = var.environments
    }
}
