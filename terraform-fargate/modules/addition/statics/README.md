참조)
https://blog.francium.tech/how-to-serve-your-website-from-aws-s3-using-terraform-94dfd16324bf
https://devops-art-factory.gitbook.io/devops-workshop/terraform/terraform-resource/storage/s3-+-cloudfront
https://medium.com/@arnavs711/creating-cloudfront-distribution-in-aws-using-terraform-4fdc93933f17
https://towardsaws.com/provision-a-static-website-on-aws-s3-and-cloudfront-using-terraform-d8004a8f629a

# REF] https://scbyun.com/915
####################Route 53 Zone(도메인) 등록
resource "aws_route53_zone" "main" {
    name = "hist-tech.net"
    comment = "hist-tech.net"
}

####################Route 53 MX Record(서브 도메인) 등록(G. Suite)
resource "aws_route53_record" "subdomain" {
    zone_id = aws_route53_zone.main.id
    name = "hist-tech.net"
    type = "NS"
    ttl = "3600"
    records = [
        "ns-219.awsdns-27.com.",
        "ns-1847.awsdns-38.co.uk.",
        "ns-1230.awsdns-25.org.",
        "ns-951.awsdns-54.net.",
    ]
}

###################Route 53 A Record(서브 도메인) 등록
resource "aws_route53_record" "add_subdomain" {
    zone_id = aws_route53_zone.main.zone_id
    name = "tutorial.hist-tech.net"
    type = "A"
    ttl = "300"
    records = ["111.111.111.111"]
}

####################Route 53 CNAME Record(서브 도메인) 등록
resource "aws_route53_record" "cname_subdomain" {
    zone_id = aws_route53_zone.main.zone_id
    name = "tutorial.hist-tech.net"
    type = "CNAME"
    ttl = "300"
    records = ["tutorial.hist-tech.net"]
}

####################ACM SSL 인증서 생성
resource "aws_acm_certificate" "cert" {
    domain_name = "hist-tech.net"
    subject_alternative_names = [ "*.hist-tech.net" ]
    validation_method = "DNS"
    lifecycle {
        create_before_destroy = true
    }
    tags = {
        Name = "hist-tech.net"
        Env = "stg"
        CreateUser = "admin@email.com"
        Owner = "iac"
        Role = "alb"
        Service = "acm"
    }
}

####################Route 53 도메인 이름 검증
resource "aws_route53_record" "cert_validation" {
    for_each = {
        for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
            name   = dvo.resource_record_name
            record = dvo.resource_record_value
            type   = dvo.resource_record_type
        }
    }
    allow_overwrite = true
    name            = each.value.name
    records         = [each.value.record]
    ttl             = 60
    type            = each.value.type
    zone_id         = aws_route53_zone.main.zone_id
}

####################ACM 인증서 유효성 검사
resource "aws_acm_certificate_validation" "cert" {
    certificate_arn         = aws_acm_certificate.cert.arn
    validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

output "acm_certificate_dns_validation_records" {
    description = "record which is used to validate acm certificate"
    value       = aws_acm_certificate.cert.*.domain_validation_options
}