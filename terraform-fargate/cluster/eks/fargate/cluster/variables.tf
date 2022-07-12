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

variable "cluster_version" {
    type = string
}

###############################################################
# Security info
###############################################################
variable "cluster_security_group_id" {
    type = string
}

variable "public_subnet_ids" {
    type = list(string)
}

variable "private_subnet_ids" {
    type = list(string)
}

###############################################################
# AWS KMS ARN
###############################################################
variable "kms_key_arn" {
    type = string
}