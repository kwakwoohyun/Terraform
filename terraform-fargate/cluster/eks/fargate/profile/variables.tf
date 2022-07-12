###############################################################
# Basic info
###############################################################
# application service name
variable "svr_name" {
    type = string
}

variable "environments" {
    type = string
}

variable "cluster_name" {
    type = string
}

###############################################################
# Subnet info
###############################################################
variable "private_subnet_ids" {
    type = list(string)
}
