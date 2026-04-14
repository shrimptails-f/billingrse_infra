# AWS 共通
variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "stage" {
  type    = string
  default = "dev"
}

variable "dev_aws_account_id" {
  type        = string
  default     = null
  description = "Dev AWS account ID used to compose GitHub Actions OIDC provider ARN. Set via TF_VAR_dev_aws_account_id."
}

variable "backend_ecr_repository_name" {
  type    = string
  default = "billingrse-dev-backend"
}
variable "ecs_task_secretsmanager_suffixes" {
  type = list(string)
  default = [
    "billingrse_dev*",
    "rds!db-*"
  ]
  description = "Secret name patterns (suffix part) that ECS tasks can read via Secrets Manager."
}

variable "github_repo_subjects" {
  type = list(string)
  default = [
    "repo:shrimptails-f/billingrse_infra:*",
    "repo:shrimptails-f/billingrse_backend:*",
    "repo:shrimptails-f/billingrse_front:*"
  ]
  description = "Allowed GitHub OIDC subjects (token.actions.githubusercontent.com:sub) that can assume the OIDC role."
}
