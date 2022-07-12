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

# eks cluster name
variable "cluster_name" {
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
# Defined Ports
###############################################################
variable "ports" {
    type = object(
        {
            ssh_port = number
            db_port = number
            http_port = number
            https_port = number
            node_from_port = number
            node_to_port = number
            any_port = number
            any_protocol = string
            tcp_protocol = string
            all_ips = list(string)
        }
    )
}