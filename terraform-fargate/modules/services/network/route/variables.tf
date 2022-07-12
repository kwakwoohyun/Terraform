###############################################################
# Basic info
###############################################################
# application service name
variable "svr_name" {
    type = string
}

# environments :: dev, stage and prod
variable "environments" {
    type = string
}

###############################################################
# Create vpc id
###############################################################
# vpc id
variable "vpc_id" {
    type = string
}

###############################################################
# Network base variables
###############################################################
# gateway id
variable "gateway_id" {
    type = string
}

# nat gateway ids
variable "nat_ids" {
    type = list(string)
}

###############################################################
# Create public subnet ids
################################################################
variable "public_subnet_ids" {
    type = list(string)
}

# private subnets ids
variable "private_subnet_ids" {
    type = list(string)
}

# private subnets ids
variable "rds_subnet_ids" {
    type = list(string)
}
