#########################################################
# AWS Resource Variables
#########################################################
# WEB Application base name
variable "svr_name" {
    type = string
}

variable "environments" {
    type = string
}

#########################################################
# RDS Resource Variables
#########################################################
# database host instance type
variable "db_instance_type" {
    type = string
}

# database name
variable "db_name" {
    type = string
}

# database subnet ids
variable "rds_subnet_ids" {
    type = list(string)
}

# security group id
variable "security_group_id" {
    type = string
}
