#####################################################################
# Basic variables
#####################################################################
variable "svr_name" {
    type = string
}

# domain name
variable "domain_name" {
    type = string
}

#####################################################################
# Static resource variables
#####################################################################
variable "endpoint" {
    type = string
}

# S3의 CF요청을 인증하기 위한 key string
variable "secret_user_agent" {
    type = string
}

variable "index_document" {
    type = string
}
