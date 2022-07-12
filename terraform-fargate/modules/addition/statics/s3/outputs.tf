###################################################################################
# S3 bucket arn
###################################################################################
output "bucket" {
    value = aws_s3_bucket.main.bucket
}

output "arn" {
    value = aws_s3_bucket.main.arn
}

output "endpoint" {
    value = aws_s3_bucket.main.website_endpoint
}

output "bucket_domain_name" {
    value = aws_s3_bucket.main.bucket_regional_domain_name
}
