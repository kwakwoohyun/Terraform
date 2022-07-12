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
# Create public subnet ids
###############################################################
variable "public_subnet_ids" {
    type = list(string)
}