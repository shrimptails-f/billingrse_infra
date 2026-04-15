terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.25.0"
    }
  }

  backend "s3" {
    bucket         = "tfstate-billingrse-shared"
    key            = "domain/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "tfstate-billingrse-lock-shared"
    encrypt        = true
  }
}

module "common" {
  source = "../../common"
}

provider "aws" {
  region = module.common.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

locals {
  front_domain_name = "${var.env_subdomain}.${module.common.root_domain_name}"
  api_domain_name   = "api.${var.env_subdomain}.${module.common.root_domain_name}"
}

# Hosted Zone は Terraform で新規作成して管理する
resource "aws_route53_zone" "this" {
  name = module.common.root_domain_name
}

locals {
  zone_id      = aws_route53_zone.this.zone_id
  name_servers = aws_route53_zone.this.name_servers
}

# ACM for API (ap-northeast-1)
resource "aws_acm_certificate" "api" {
  domain_name       = local.api_domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "api_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = local.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "api" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for r in aws_route53_record.api_validation : r.fqdn]
}

# ACM for Front (us-east-1, CloudFront)
resource "aws_acm_certificate" "front" {
  provider          = aws.us_east_1
  domain_name       = local.front_domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "front_validation" {
  for_each = {
    for dvo in aws_acm_certificate.front.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = local.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "front" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.front.arn
  validation_record_fqdns = [for r in aws_route53_record.front_validation : r.fqdn]
}
