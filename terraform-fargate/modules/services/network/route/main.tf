###################################################################################
# Public Route
###################################################################################
# Route table: attach Internet Gateway 
resource "aws_route_table" "public" {
    vpc_id = var.vpc_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = var.gateway_id
    }
    tags = {
        Name = format("%s-%s", var.svr_name, "public")
    }
}

# Route Table connect subnets
resource "aws_route_table_association" "public" {
    count = length(var.public_subnet_ids)
    subnet_id = element(var.public_subnet_ids, count.index)
    route_table_id = element(aws_route_table.public.*.id, count.index)
}

###################################################################################
# Private Route :: Worker Nodes & Database
###################################################################################
# Route table: attach Internet Gateway 
resource "aws_route_table" "private" {
    vpc_id = var.vpc_id

    count = length(var.nat_ids)
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = element(var.nat_ids, count.index)
    }
    tags = {
        Name = format("%s-%s", var.svr_name, "private${count.index+1}")
    }
}

# Route Table connect subnets
resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_ids)
    subnet_id = element(var.private_subnet_ids, count.index)
    route_table_id = element(aws_route_table.private.*.id, count.index)
}

###################################################################################
# Database Route
###################################################################################
# Route table: attach Internet Gateway 
resource "aws_route_table" "rds" {
    vpc_id = var.vpc_id

    count = length(var.nat_ids)
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = element(var.nat_ids, count.index)
    }
    tags = {
        Name = format("%s-%s", var.svr_name, "rds${count.index+1}")
    }
}

# Route Table connect subnets
resource "aws_route_table_association" "rds" {
    count = length(var.rds_subnet_ids)
    subnet_id = element(var.rds_subnet_ids, count.index)
    route_table_id = element(aws_route_table.rds.*.id, count.index)
}
