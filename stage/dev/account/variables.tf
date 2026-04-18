# AWS 共通
variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "stage" {
  type    = string
  default = "dev"
}

variable "backend_ecr_repository_name" {
  type    = string
  default = "billingrse-dev-backend"
}

variable "ecr_repository_names" {
  type = list(string)
  default = [
    "billingrse-dev-backend",
    "billingrse-dev-db-init",
    "billingrse-dev-db-tools",
    "billingrse-dev-redis",
  ]
}

variable "ecs_task_secretsmanager_suffixes" {
  type = list(string)
  default = [
    "billingrse_dev*",
    "rds!db-*"
  ]
  description = "Secret name patterns (suffix part) that ECS tasks can read via Secrets Manager."
}

variable "github_infra_repo_subjects" {
  type = list(string)
  default = [
    "repo:shrimptails-f/billingrse_infra:*"
  ]
  description = "Allowed GitHub OIDC subjects for infra deploy role."
}

variable "github_backend_repo_subjects" {
  type = list(string)
  default = [
    "repo:shrimptails-f/billingrse_backend:*"
  ]
  description = "Allowed GitHub OIDC subjects for backend deploy role."
}

variable "github_front_repo_subjects" {
  type = list(string)
  default = [
    "repo:shrimptails-f/billingrse_front:*"
  ]
  description = "Allowed GitHub OIDC subjects for front deploy role."
}

variable "github_repo_subjects" {
  type        = list(string)
  default     = []
  description = "Deprecated compatibility subjects for shared OIDC trust."
}
