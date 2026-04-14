terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.25.0"
    }
  }

  backend "s3" {
    bucket         = "tfstate-billingrse-dev"
    dynamodb_table = "tfstate-billingrse-lock-dev"
    region         = "ap-northeast-1"
    key            = "account/terraform.tfstate"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  ecs_task_secretsmanager_arns = [
    for suffix in var.ecs_task_secretsmanager_suffixes :
    "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${suffix}"
  ]
  github_actions_oidc_provider_arn = var.dev_aws_account_id != null && var.dev_aws_account_id != "" ? "arn:aws:iam::${var.dev_aws_account_id}:oidc-provider/token.actions.githubusercontent.com" : null
}

module "account" {
  source = "../../../modules/account"

  aws_region                       = var.aws_region
  stage                            = var.stage
  backend_ecr_repository_name      = var.backend_ecr_repository_name
  ecr_repository_names             = var.ecr_repository_names
  ecs_task_secretsmanager_arns     = local.ecs_task_secretsmanager_arns
  github_actions_oidc_provider_arn = local.github_actions_oidc_provider_arn
  github_repo_subjects             = var.github_repo_subjects
}
