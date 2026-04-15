output "route53_zone_id" {
  description = "Hosted zone ID"
  value       = local.zone_id
}

output "route53_zone_arn" {
  description = "Hosted zone ARN"
  value       = aws_route53_zone.this.arn
}

output "route53_name_servers" {
  description = "Name servers for the hosted zone"
  value       = local.name_servers
}

output "front_domain_name" {
  description = "Front (CloudFront) domain"
  value       = local.front_domain_name
}

output "api_domain_name" {
  description = "API (ALB) domain"
  value       = local.api_domain_name
}

output "front_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (us-east-1)"
  value       = aws_acm_certificate_validation.front.certificate_arn
}

output "api_certificate_arn" {
  description = "ACM certificate ARN for ALB (ap-northeast-1)"
  value       = aws_acm_certificate_validation.api.certificate_arn
}
