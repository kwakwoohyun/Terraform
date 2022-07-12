###############################################################
# Basic info
###############################################################
# application service name
variable "svr_name" {
    type = string
}

# environments :: dev, stage and prod
variable "cluster_name" {
    type = string
}

# environments :: dev, stage and prod
variable "environments" {
    type = string
}

###############################################################
# VPC ID
###############################################################
variable "vpc_id" {
    type = string
}

###############################################################
# AWS KMS Key
###############################################################
variable "kms_key_arn" {
    type = string
}
