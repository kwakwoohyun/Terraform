###############################################################
# Basic info
###############################################################
variable "environments" {
    type = string
}

variable "cluster_name" {
    type = string
}

###############################################################
# Security info
###############################################################
variable "node_security_group_id" {
    type = string
}

variable "private_subnet_ids" {
    type = list(string)
}

variable "key_name" {
    type = string
}

###############################################################
# Instance info
###############################################################
variable "instance_type" {
    type = string
}

variable "min_size" {
    type = number
}

variable "max_size" {
    type = number
}
