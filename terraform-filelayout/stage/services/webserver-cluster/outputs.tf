output "alb_dns_name" {
  value       = aws_lb.wkwak-terraform-instance.dns_name
  description = "The domain name of the load balancer"
}