provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_launch_configuration" "wkwak-terraform-instance" {
  image_id        = "ami-0fd0765afb77bcca7"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.wkwak-terraform-instance-security-group.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "wkwak-terraform-instance" {
  launch_configuration = aws_launch_configuration.wkwak-terraform-instance.name
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.wkwak-terraform-asg.arn]
  health_check_type = "ELB"

  min_size = 1
  max_size = 2

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "wkwak-terraform-asg-example"
  }
}

resource "aws_security_group" "wkwak-terraform-instance-security-group" {
  name = "wkwak-terraform-instance-security-group"

  ingress {
    from_port   = var.server_port
    protocol    = "tcp"
    to_port     = var.server_port
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_lb" "wkwak-terraform-instance" {
  name               = "wkwak-terraform-asg-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.wkwak-terraform-alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wkwak-terraform-instance.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found!"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "wkwak-terraform-asg" {
  name     = "wkwak-terraform-asg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "wkwak-terraform-asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wkwak-terraform-asg.arn
  }
}

resource "aws_security_group" "wkwak-terraform-alb" {
  name = "wkwak-terraform-alb"

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

terraform {
  backend "s3" {
    bucket = "wkwak-terraform-up-and-running-state"
    # 테라폼 상태 파일을 저장할 S3 버킷 내의 파일 경로
    key    = "stage/service/webserver-cluster/terraform.tfstate"
    region = "ap-northeast-2"

    # 잠금에 사용할 DynamoDB 테이블
    dynamodb_table = "wkwak-terraform-up-and-running-locks"
    # encrypt = true 설정시 테라폼 상태가 S3 디스크에 저장될 때 암호화된다.
    encrypt        = true
  }
}