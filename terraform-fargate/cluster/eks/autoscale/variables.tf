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

# current aws user name
variable "user_name" {
    type = string
}

###############################################################
# Cluster Role ARN
###############################################################
variable "cluster_role_arn" {
    type = string
}

variable "node_role_arn" {
    type = string
}

variable "node_profile_name" {
    type = string
}

###############################################################
# Security info
###############################################################
variable "cluster_security_group_id" {
    type = string
}

variable "node_security_group_id" {
    type = string
}

variable "bastion_security_group_id" {
    type = string
}

variable "key_name" {
    type = string
}

###############################################################
# Subnet info
###############################################################
variable "public_subnet_ids" {
    type = list(string)
}

variable "private_subnet_ids" {
    type = list(string)
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

variable "enable_autoscaling" {
    type = bool
}
