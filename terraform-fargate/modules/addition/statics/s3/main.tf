#####################################################################
# S3 bucket policy
#####################################################################
data "aws_iam_policy_document" "bucket_policy" {
    statement {
        sid = "AllowReadFromAll"
        actions = ["s3:GetObject"]
        resources = ["arn:aws:s3:::${var.svr_name}.${var.domain_name}/*"]
        principals {
            type = "*"
            identifiers = ["*"]
        }
    }
}

#####################################################################
# S3 bucket 
#####################################################################
resource "aws_s3_bucket" "main" {
    bucket = format("%s.%s", var.svr_name, var.domain_name)

    # bucket 컨텐츠를 강제로 삭제
    force_destroy = var.s3_force_destroy

    tags = {
        "Name" = format("%s.%s", var.svr_name, var.domain_name)
        Environments = var.environments
    }
}

# s3 bucket policy
resource "aws_s3_bucket_policy" "main" {
    bucket = aws_s3_bucket.main.id
    policy = data.aws_iam_policy_document.bucket_policy.json
}

# website setting
resource "aws_s3_bucket_website_configuration" "main" {
    bucket = aws_s3_bucket.main.id

    index_document {
        suffix = var.index_document
    }

    error_document {
        key = var.error_document
    }
}

# s3 저장소 acl
resource "aws_s3_bucket_acl" "main" {
    bucket = aws_s3_bucket.main.id
    acl = "private"
}

resource "aws_s3_bucket_public_access_block" "access_block" {
    bucket = aws_s3_bucket.main.bucket
    
    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
}

#####################################################################
# S3 bucket object :: index
#####################################################################
# file upload
resource "aws_s3_object" "index" {
    bucket = aws_s3_bucket.main.bucket
    key = "index.html"
    source = "${path.module}/initial_files/index.html"
    content_type = "text/html"
}

#####################################################################
# S3 bucket object :: error
#####################################################################
# file upload
resource "aws_s3_object" "error" {
    bucket = aws_s3_bucket.main.bucket
    key = "error.html"
    source = "${path.module}/initial_files/error.html"
    content_type = "text/html"
}
