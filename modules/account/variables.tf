# AWS 共通
variable "aws_region" { type = string }
variable "stage" { type = string }

variable "backend_ecr_repository_name" {
  type        = string
  description = "Backend ECR repository name to create."
}

variable "ecr_repository_names" {
  type        = list(string)
  description = "ECR repository names to create."
  default     = []
}

variable "ecs_task_secretsmanager_arns" {
  type        = list(string)
  description = "Secrets Manager ARNs that ECS tasks (task role) can read via GetSecretValue."
  default     = []
}

variable "ecs_task_ses_from_addresses" {
  type        = list(string)
  description = "Allowed From addresses for ECS task SES send operations."
  default     = []
}

variable "github_repo_subjects" {
  type        = list(string)
  description = "Deprecated fallback subjects for all GitHub OIDC roles."
  default     = []
}

variable "github_infra_repo_subjects" {
  type        = list(string)
  description = "Allowed GitHub OIDC subjects for infra deploy role."
  default     = []
}

variable "github_backend_repo_subjects" {
  type        = list(string)
  description = "Allowed GitHub OIDC subjects for backend deploy role."
  default     = []
}

variable "github_front_repo_subjects" {
  type        = list(string)
  description = "Allowed GitHub OIDC subjects for front deploy role."
  default     = []
}

variable "github_actions_oidc_provider_arn" {
  type        = string
  description = "Existing GitHub Actions OIDC provider ARN to reuse. If null, the provider is created by this module."
  default     = null
}

variable "ecr_pull_allowed_vpce_ids" {
  type        = list(string)
  description = "Allowed VPC endpoint IDs for ECS task execution role ECR pull operations."
  default     = []
}

locals {
  project_name = "billingrse"
  deploy_name  = "${local.project_name}-${var.stage}"
  ecr_repository_names = length(var.ecr_repository_names) > 0 ? var.ecr_repository_names : [
    var.backend_ecr_repository_name
  ]
  front_bucket_name = "${local.deploy_name}-front"
  common_tags = {
    Project = local.project_name
    Managed = "terraform"
    Stage   = var.stage
  }
}
