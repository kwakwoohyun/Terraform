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

variable "cluster_name" {
    type = string
}

###############################################################
# CIDR block
###############################################################
# vpc cidr block
variable "cidr_block" {
    type = string
}