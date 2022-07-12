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
# CIDR block
###############################################################
# subnet cidr blocks
variable "subnets" {
    type = object(
        {
            public = map(string)
            private = map(string)
            rds = map(string)
        }
    )
}