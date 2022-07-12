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
# EKS cluster oidc issuer
###############################################################
variable "cluster_oidc_issuer" {
    type = string
}
