###############################################################
# Internet Gateway
###############################################################
output "gateway_id" {
    value = aws_internet_gateway.igw.id
}

###############################################################
# NAT Gateway
###############################################################
output "nat_ids" {
    value = [
        for key, value in aws_nat_gateway.nat: value.id
    ]
}