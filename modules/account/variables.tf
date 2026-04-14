# AWS 共通
variable "aws_region" { type = string }
variable "stage" { type = string }

variable "backend_ecr_repository_name" {
  type        = string
  description = "Backend ECR repository name to create."
}

variable "ecs_task_secretsmanager_arns" {
  type        = list(string)
  description = "Secrets Manager ARNs that ECS tasks (task role) can read via GetSecretValue."
  default     = []
}

variable "github_repo_subjects" {
  type        = list(string)
  description = "Allowed GitHub OIDC subjects (token.actions.githubusercontent.com:sub) that can assume the OIDC role."
}

variable "github_actions_oidc_provider_arn" {
  type        = string
  description = "Existing GitHub Actions OIDC provider ARN to reuse. If null, the provider is created by this module."
  default     = null
}

locals {
  project_name      = "billingrse"
  deploy_name       = "${local.project_name}-${var.stage}"
  front_bucket_name = "${local.deploy_name}-front"
  common_tags = {
    Project = local.project_name
    Managed = "terraform"
    Stage   = var.stage
  }
}
