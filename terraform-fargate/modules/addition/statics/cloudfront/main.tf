# REF URL) https://devops-art-factory.gitbook.io/devops-workshop/terraform/terraform-resource/storage/s3-+-cloudfront
#####################################################################
# ACM
#####################################################################
# # ACM 인증서 리소스
# resource "aws_acm_certificate" "cert" {
#     # 인증서를 발급받을 도메인 명
#     domain_name = var.domain_name
#     subject_alternative_names = ["*.${var.domain_name}"]
#     # 인증서 검증 방법 - DNS 또는 EMAIL
#     validation_method = "DNS"

#     lifecycle {
#         create_before_destroy = true
#     }

#     tags = {
#         "Name" = var.domain_name
#     }
# }

# # ACM 인증서의 유효성 검사
# resource "aws_acm_certificate_validation" "cert" {
#     # 검증 대상 인증서의 ARN
#     certificate_arn = aws_acm_certificate.cert.arn
#     # 유효성 검사를 구현하는 FQDN 목록 (DNS 검증방법 ACM 인증서에만 유효)
#     validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }

#####################################################################
# Route53
#####################################################################
# # Route 53 호스팅 영역을 조회
# data "aws_route53_zone" "main" {
#     name = var.domain_name
#     private_zone = false
# }

# # 신규 서브도메인 등록
# resource "aws_route53_record" "add_subdomain" {
#     zone_id = data.aws_route53_zone.main.zone_id
#     name = "${var.cluster_name}.${var.domain_name}"
#     type = "A"
#     ttl = "300"
#     records = ["${var.cluster_name}.${var.domain_name}"]
# }

# # routing 정책 정보
# resource "aws_route53_record" "cert_validation" {
#     for_each = {
#         for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
#             name   = dvo.resource_record_name
#             record = dvo.resource_record_value
#             type   = dvo.resource_record_type
#         }
#     }

#     name = each.value.name
#     type = each.value.type
#     zone_id = data.aws_route53_zone.main.id
#     records = [each.value.record]
#     ttl = 60
# }

#####################################################################
# CloudFront
#####################################################################
resource "aws_cloudfront_distribution" "main" {
    # http 버전 (default = http2)
    http_version = "http2"

    # 이 배포에 대한 출처
    origin {
        # 원본에 대한 식별자
        origin_id = "origin-${var.svr_name}.${var.domain_name}" 
        # S3 bucket의 DNS 도메인 이름 또는 사용자 지정 웹 사이트
        domain_name = var.endpoint

        # 사용자 지정 origin 구성정보
        custom_origin_config {
            # http-only: http로 서비스, https-only: https로 서비스, match-viewer: 사용자 지정에 따름
            origin_protocol_policy = "match-viewer"
            http_port = "80"
            https_port = "443"
            origin_ssl_protocols = ["TLSv1.2"]
        }

        # 원본으로 보낼 header 데이터
        custom_header {
            name = "User-Agent"
            value = var.secret_user_agent
        }
    }

    # 배포의 콘텐츠에 대한 최종 사용자 요청 수락 여부
    enabled = true
    is_ipv6_enabled = false

    # 최종 사용자가 root url을 요청할 때 return할 객체 (index.html)
    default_root_object = var.index_document

    # 이 배포에 대한 추가 CNAME(대체도메인, 있는 경우)
    # aliases = concat(["${var.svr_name}.${var.domain_name}"])
    
    # 기본 캐쉬 동작 설정
    default_cache_behavior {
        # cloudfront에 요청할 origin id
        target_origin_id = "origin-${var.svr_name}.${var.domain_name}"
        # cloudfront에서 처리하고 s3 bucket에 전달할 HTTP method
        allowed_methods = ["GET", "HEAD"]
        # HTTP method 요청에 대한 응답을 캐싱
        cached_methods = ["GET", "HEAD"]
        # 웹 요청의 콘첸츠를 압축할 지 여부
        compress = true

        # cloudfront에서 query, cookie, header 처리방법을 지정하는 값 구성
        forwarded_values {
            query_string = false

            cookies {
                forward = "none"
            }
        }

        # 사용자 요청 경로가 PathPattern 경로 패턴과 일치할 때 사용할 프로토콜 지정
        viewer_protocol_policy = "allow-all"    # allow-all, https-only, redirect-to-https
        # 객체가 업데이트 되었는지 확인하기 위해 Origin을 쿼리하기 전에 객체가 캐시에 유지되기 원하는 최소시간.
        min_ttl = 0
        # 캐시되는 기본 시간 (초)
        default_ttl = 300
        # 캐시되는 최대 시간 (초)
        max_ttl = 1200
    }

    # List of Custom Cache behavior
    # This behavior will be applied before default
    ordered_cache_behavior {
        path_pattern = "/*"

        target_origin_id = "origin-${var.svr_name}.${var.domain_name}"
        allowed_methods  = ["GET", "HEAD"]
        cached_methods   = ["GET", "HEAD"]
        compress = false

        viewer_protocol_policy = "allow-all"
        min_ttl                = 0
        default_ttl            = 3600
        max_ttl                = 3600

        forwarded_values {
            query_string = false

            cookies {
                forward = "none"
            }
        }
    }

    # 이 배포에 대한 제한 구성
    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    # SSL 구성
    viewer_certificate {
        cloudfront_default_certificate = true
    }

    # custom_error_response {
    #     error_code = 400
    #     error_caching_min_ttl = var.error_ttl
    # }
    # custom_error_response {
    #     error_code = 403
    #     error_caching_min_ttl = var.error_ttl
    # }
    # custom_error_response {
    #     error_code = 404
    #     error_caching_min_ttl = var.error_ttl
    # }
    # custom_error_response {
    #     error_code = 405
    #     error_caching_min_ttl = var.error_ttl
    # }
}
