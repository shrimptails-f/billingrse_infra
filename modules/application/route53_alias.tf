locals {
  front_alias_enabled = var.front_domain_name != "" && var.route53_zone_id != "" && var.front_certificate_arn != ""
  api_alias_enabled   = var.api_domain_name != "" && var.route53_zone_id != ""
}

resource "aws_route53_record" "front_alias_a" {
  count   = local.front_alias_enabled ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.front_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.front.domain_name
    zone_id                = aws_cloudfront_distribution.front.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_alias_a" {
  count   = local.api_alias_enabled ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.api_domain_name
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = false
  }
}
