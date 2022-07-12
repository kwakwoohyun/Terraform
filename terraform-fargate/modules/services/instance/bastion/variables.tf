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

###############################################################
# Create public subnet ids
################################################################
variable "public_subnet_ids" {
    type = list(string)
}

###############################################################
# Create secutiry group id
################################################################
variable "bastion_security_group_id" {
    type = string
}

###############################################################
# Instance variables
###############################################################
variable "ami" {
    type = string
}

variable "instance_type" {
    type = string
}

