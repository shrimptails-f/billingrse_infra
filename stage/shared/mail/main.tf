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
    key            = "mail/terraform.tfstate"
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

data "terraform_remote_state" "domain" {
  backend = "s3"

  config = {
    bucket         = "tfstate-billingrse-shared"
    dynamodb_table = "tfstate-billingrse-lock-shared"
    region         = "ap-northeast-1"
    key            = "domain/terraform.tfstate"
    encrypt        = true
  }
}

locals {
  project_name       = module.common.app_name
  deploy_name        = "${local.project_name}-${var.env_subdomain}"
  mail_domain_name   = "${var.env_subdomain}.${module.common.root_domain_name}"
  default_from_email = "${var.from_local_part}@${local.mail_domain_name}"
  dmarc_domain_name  = "_dmarc.${local.mail_domain_name}"
  dmarc_record_value = "v=DMARC1; p=${var.dmarc_policy}; adkim=${var.dmarc_adkim}; aspf=${var.dmarc_aspf}"
  common_tags = {
    Project = local.project_name
    Managed = "terraform"
    Stage   = var.env_subdomain
  }
}

resource "aws_ses_domain_identity" "this" {
  domain = local.mail_domain_name
}

resource "aws_route53_record" "verification" {
  zone_id = data.terraform_remote_state.domain.outputs.route53_zone_id
  name    = "_amazonses.${local.mail_domain_name}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.this.verification_token]

  allow_overwrite = true
}

resource "aws_ses_domain_identity_verification" "this" {
  domain = aws_ses_domain_identity.this.id

  depends_on = [aws_route53_record.verification]
}

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain

  depends_on = [aws_ses_domain_identity_verification.this]
}

resource "aws_route53_record" "dkim" {
  for_each = {
    token_0 = aws_ses_domain_dkim.this.dkim_tokens[0]
    token_1 = aws_ses_domain_dkim.this.dkim_tokens[1]
    token_2 = aws_ses_domain_dkim.this.dkim_tokens[2]
  }

  zone_id = data.terraform_remote_state.domain.outputs.route53_zone_id
  name    = "${each.value}._domainkey.${local.mail_domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${each.value}.dkim.amazonses.com"]

  allow_overwrite = true
}

resource "aws_route53_record" "dmarc" {
  zone_id = data.terraform_remote_state.domain.outputs.route53_zone_id
  name    = local.dmarc_domain_name
  type    = "TXT"
  ttl     = 600
  records = [local.dmarc_record_value]

  allow_overwrite = true
}

resource "aws_ses_configuration_set" "default" {
  name                       = "${local.deploy_name}-default"
  reputation_metrics_enabled = true
}
