#####################################################################
# Basic variables
#####################################################################
variable "svr_name" {
    type = string
}

variable "environments" {
    type = string
}

# domain name
variable "domain_name" {
    type = string
}

#####################################################################
# Static resource variables
#####################################################################
variable "index_document" {
    type = string
}

variable "error_document" {
    type = string
}

# s3 컨텐츠 강제 삭제 여부
variable "s3_force_destroy" {
    type = string
}