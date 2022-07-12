###############################################################
# ECR repository
###############################################################
resource "aws_ecr_repository" "repository" {
    name = var.cluster_name
	image_tag_mutability = "IMMUTABLE"
}

###############################################################
# ECR repository policy
###############################################################
resource "aws_ecr_repository_policy" "repo-policy" {
    repository = aws_ecr_repository.repository.name
    policy = <<EOF
    {
        "Version": "2008-10-17",
        "Statement": [
            {
                "Sid": "adds full ecr access to the demo repository",
                "Effect": "Allow",
                "Principal": "*",
                "Action": [
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:BatchGetImage",
                    "ecr:CompleteLayerUpload",
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:GetLifecyclePolicy",
                    "ecr:InitiateLayerUpload",
                    "ecr:PutImage",
                    "ecr:UploadLayerPart"
                ]
            }
        ]
    }
    EOF

    depends_on = [aws_ecr_repository.repository]
}

###############################################################
# ECR repository login
###############################################################
resource "null_resource" "null_for_ecr_get_login_password" {
    provisioner "local-exec" {
    command = <<EOF
        aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${aws_ecr_repository.repository.repository_url}
    EOF
    }

    depends_on = [aws_ecr_repository_policy.repo-policy]
}
