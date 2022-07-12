###############################################################
# Basic info
###############################################################
# current aws user info
variable "user_name" {
    type = string
    default = "syou"
}

# aws region :: seoul region
variable "aws_region" {
    type = string
    default = "ap-northeast-2"
}

# application service name
variable "svr_name" {
    type = string
    default = "webapps"
}

# environments :: dev, stage and prod
variable "environments" {
    type = string
    default = "dev"
}

# domain name
variable "domain_name" {
    type = string
    default = "tutorials.net"
}

# cluster version
variable "cluster_version" {
    type = string
    default = "1.21"
}

###############################################################
# CIDR block
###############################################################
# vpc cidr block
variable "cidr_block" {
    type = string
    default = "192.168.0.0/16"
}

# subnet cidr blocks
variable "subnets" {
    type = object(
        {
            public = map(string)
            private = map(string)
            rds = map(string)
        }
    )

    default = {
        public = {
            "192.168.1.0/24" = "ap-northeast-2a"
            "192.168.2.0/24" = "ap-northeast-2c"
        }
        private = {
            "192.168.101.0/24" = "ap-northeast-2a"
            "192.168.102.0/24" = "ap-northeast-2c"
        }
        rds = {
            "192.168.201.0/24" = "ap-northeast-2a"
            "192.168.202.0/24" = "ap-northeast-2c"
        }
    }
}

###############################################################
# Predefine port infos
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

    default = {
        ssh_port = 22
        db_port = 5432
        http_port = 80
        https_port = 443
        node_from_port = 1025
        node_to_port = 65535
        any_port = 0
        any_protocol = "-1"
        tcp_protocol = "tcp"
        all_ips = ["0.0.0.0/0"]
    }
}

###############################################################
# Instance variables
###############################################################
variable "ami" {
    type = map(string)
    default = {
        "instance" = "ami-0263588f2531a56bd",
        "bastion" = "ami-0263588f2531a56bd"
    }
}

variable "instance_type" {
    type = map(string)
    default = {
        "instance" = "t3.medium",
        "bastion" = "t2.micro",
        "database" = "db.t2.micro"
    }
}

###############################################################
# Cluster variables
###############################################################
variable "min_size" {
    type = number
    default = 2
}

variable "max_size" {
    type = number
    default = 3
}

# auto scaling on/off
variable "enable_autoscaling" {
    type = bool
    default = false
}

###############################################################
# RDS info
###############################################################
# database name
variable "db_name" {
    type = string
    default = "webapps_stage_db"
}

###############################################################
# Static web page variables
###############################################################
variable "index_document" {
    type = string
    default = "index.html"
}

variable "error_document" {
    type = string
    default = "error.html"
}

# s3 컨텐츠 강제 삭제 여부
variable "s3_force_destroy" {
    type = string
    default = "true"
}

# S3의 CF요청을 인증하기 위한 key string
variable "secret_user_agent" {
    type = string
    default = "SECRET STRING"
}
