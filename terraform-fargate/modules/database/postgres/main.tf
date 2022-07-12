###################################################################################
# Database Subnet Group
###################################################################################
resource "aws_db_subnet_group" "postgres" {
    name = format("%s-%s", var.svr_name, "postgres")
    subnet_ids = var.rds_subnet_ids

    tags = {
        Name = format("%s-%s", var.svr_name, "postgres")
        Environment = var.environments
    }
}

###################################################################################
# Database Parameter Group
###################################################################################
resource "aws_db_parameter_group" "postgres" {
    name = format("%s-%s", var.svr_name, "postgres")
    family = "postgres11"

    parameter {
        name = "client_encoding"
        value = "utf8"
    }
}

###################################################################################
# Database Secret Manager
###################################################################################
# AWS Secret Manager에서 해당 ID로 선행하여 작성한 상태여야 한다.
data "aws_secretsmanager_secret_version" "creds" {
    secret_id = "postgres-master-creds-stage"
}

# After Importing the secrets Storing the Imported Secrets into Locals
locals {
    db_creds = jsondecode(
        data.aws_secretsmanager_secret_version.creds.secret_string
    )
}

###################################################################################
# PostgreSQL Database
###################################################################################
resource "aws_db_instance" "postgres" {
    identifier = format("%s-%s", var.svr_name, "postgres")
    engine = "postgres"
    engine_version = "11"
    db_name = var.db_name
    instance_class = var.db_instance_type
    allocated_storage = 30
    storage_type = "gp2"
    username = local.db_creds.username
    password = local.db_creds.password
    db_subnet_group_name = aws_db_subnet_group.postgres.name
    publicly_accessible = false
    multi_az = false
    backup_window = "18:00-18:30"
    maintenance_window = "sat:19:00-sat:19:30"
    auto_minor_version_upgrade = false
    parameter_group_name = aws_db_parameter_group.postgres.name
    vpc_security_group_ids = [var.security_group_id]
    copy_tags_to_snapshot = false
    backup_retention_period = 7
    deletion_protection = false
    skip_final_snapshot = true
}
