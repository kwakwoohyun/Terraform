###############################################################
# Basic info
###############################################################
variable "environments" {
    type = string
}

variable "svr_name" {
    type = string
}

variable "cluster_name" {
    type = string
}

###############################################################
# Cluster info
###############################################################
variable "nodegroup_role_arn" {
    type = string
    default = ""
}

variable "fargate_profile_arn" {
    type = string
}
