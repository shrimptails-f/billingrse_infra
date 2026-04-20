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

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket         = "tfstate-billingrse-dev"
    dynamodb_table = "tfstate-billingrse-lock-dev"
    region         = "ap-northeast-1"
    key            = "network/terraform.tfstate"
    encrypt        = true
  }
}

locals {
  ecs_task_secretsmanager_arns = [
    for suffix in var.ecs_task_secretsmanager_suffixes :
    "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${suffix}"
  ]
  github_actions_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
  ecr_pull_allowed_vpce_ids = [
    data.terraform_remote_state.network.outputs.ecr_api_vpc_endpoint_id,
    data.terraform_remote_state.network.outputs.ecr_dkr_vpc_endpoint_id,
  ]
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
  github_infra_repo_subjects       = var.github_infra_repo_subjects
  github_backend_repo_subjects     = var.github_backend_repo_subjects
  github_front_repo_subjects       = var.github_front_repo_subjects
  ecr_pull_allowed_vpce_ids        = local.ecr_pull_allowed_vpce_ids
}
