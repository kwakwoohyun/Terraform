###################################################################################
# Fargate Profile Output
###################################################################################
# Fargate ARN Role
output "fargate_profile_arn" {
    value = aws_iam_role.fargate.arn
}
