output "ses_domain_identity_arn" {
  description = "SES domain identity ARN."
  value       = aws_ses_domain_identity.this.arn
}

output "ses_domain_name" {
  description = "Verified SES mail domain."
  value       = aws_ses_domain_identity.this.domain
}

output "default_from_email" {
  description = "Default sender address to be used by application stacks."
  value       = local.default_from_email
}

output "dmarc_domain_name" {
  description = "DMARC record name."
  value       = local.dmarc_domain_name
}

output "dmarc_record_value" {
  description = "DMARC record value currently managed by this stack."
  value       = local.dmarc_record_value
}

output "ses_configuration_set_name" {
  description = "Default SES configuration set name."
  value       = aws_ses_configuration_set.default.name
}
