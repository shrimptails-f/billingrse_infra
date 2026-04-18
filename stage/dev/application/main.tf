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
    key            = "application/terraform.tfstate"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

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

data "terraform_remote_state" "account" {
  backend = "s3"

  config = {
    bucket         = "tfstate-billingrse-dev"
    dynamodb_table = "tfstate-billingrse-lock-dev"
    region         = "ap-northeast-1"
    key            = "account/terraform.tfstate"
    encrypt        = true
  }
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
  account_ecr_repository_urls = try(data.terraform_remote_state.account.outputs.ecr_repository_urls, {})

  backend_repository_url = data.terraform_remote_state.account.outputs.backend_ecr_repository_url
  redis_repository_url   = lookup(local.account_ecr_repository_urls, var.redis_repository_name, "")
  db_init_repository_url = lookup(local.account_ecr_repository_urls, var.db_init_repository_name, "")
  db_tools_repository_url = lookup(local.account_ecr_repository_urls, var.db_tools_repository_name, "")

  backend_container_image = var.backend_container_image != "" ? var.backend_container_image : "${local.backend_repository_url}:${var.backend_image_tag}"
  redis_container_image   = var.redis_container_image != "" ? var.redis_container_image : (local.redis_repository_url != "" ? "${local.redis_repository_url}:${var.redis_image_tag}" : "redis:7.2-alpine")
  db_init_image           = var.db_init_image != "" ? var.db_init_image : (local.db_init_repository_url != "" ? "${local.db_init_repository_url}:${var.db_init_image_tag}" : "public.ecr.aws/docker/library/alpine:3.19")
  db_tools_image          = var.db_tools_image != "" ? var.db_tools_image : (local.db_tools_repository_url != "" ? "${local.db_tools_repository_url}:${var.db_tools_image_tag}" : "public.ecr.aws/docker/library/alpine:3.19")

  front_domain_name     = var.front_domain_name != "" ? var.front_domain_name : try(data.terraform_remote_state.domain.outputs.front_domain_name, "")
  front_certificate_arn = var.front_certificate_arn != "" ? var.front_certificate_arn : try(data.terraform_remote_state.domain.outputs.front_certificate_arn, "")
  api_domain_name       = var.api_domain_name != "" ? var.api_domain_name : try(data.terraform_remote_state.domain.outputs.api_domain_name, "")
  route53_zone_id       = var.route53_zone_id != "" ? var.route53_zone_id : try(data.terraform_remote_state.domain.outputs.route53_zone_id, "")
  alb_certificate_arn   = var.alb_certificate_arn != "" ? var.alb_certificate_arn : try(data.terraform_remote_state.domain.outputs.api_certificate_arn, "")

  backend_environment = {
    APP                      = var.stage
    APP_NAME                 = "Billingrse"
    AWS_REGION               = var.aws_region
    APP_SECRET_NAME          = "billingrse_dev"
    GO_PORT                  = "8080"
    APP_ROOT                 = "/home/dev/backend"
    IS_HIDDEN_SQL            = "true"
    IS_HIDDEN_TEST_SQL       = "true"
    MYSQL_PORT               = "3306"
    MYSQL_DATABASE           = "development"
    MYSQL_TEST_DATABASE      = "test"
    SMTP_HOST                = "mailhog"
    SMTP_PORT                = "1025"
    EMAIL_FROM_ADDRESS       = "no-reply@local.auth.example.com"
    REDIS_HOST               = "redis"
    REDIS_PORT               = "6379"
    REDIS_DB                 = "0"
    RATE_LIMIT_SCRIPT_PATH   = "internal/library/redis/script/scripts/rate_limit.lua"
    USE_SSL                  = "TRUE"
    DOMAIN                   = local.api_domain_name
    FRONT_DOMAIN             = "https://${local.front_domain_name}"
    FRONT_SSL_DOMAIN         = "https://${local.front_domain_name}"
    EMAIL_GMAIL_REDIRECT_URL = "https://${local.front_domain_name}/mail-account-connections/gmail/callback"
    // DB_HOST DB_PORT DB_NAME REDIS_HOST REDIS_PORTはデプロイ時でないと決まらないのでここでは設定しない。
  }
}

module "application" {
  source = "../../../modules/application"

  aws_region                 = var.aws_region
  stage                      = var.stage
  vpc_id                     = data.terraform_remote_state.network.outputs.vpc_id
  public_subnet_ids          = data.terraform_remote_state.network.outputs.public_subnet_ids
  private_db_subnet_ids      = data.terraform_remote_state.network.outputs.private_db_subnet_ids
  alb_security_group_id      = data.terraform_remote_state.network.outputs.alb_security_group_id
  app_security_group_id      = data.terraform_remote_state.network.outputs.app_security_group_id
  db_security_group_id       = data.terraform_remote_state.network.outputs.db_security_group_id
  redis_security_group_id    = data.terraform_remote_state.network.outputs.redis_security_group_id
  target_group_arn           = data.terraform_remote_state.network.outputs.app_target_group_arn
  task_execution_role_arn    = data.terraform_remote_state.account.outputs.ecs_task_execution_role_arn
  task_role_arn              = data.terraform_remote_state.account.outputs.ecs_task_role_arn
  db_init_task_role_arn      = var.db_init_task_role_arn
  backend_container_image    = local.backend_container_image
  db_init_image              = local.db_init_image
  db_tools_image             = local.db_tools_image
  db_init_secret_name        = var.db_init_secret_name
  db_init_mysql_database     = var.db_init_mysql_database
  db_tools_task_cpu          = var.db_tools_task_cpu
  db_tools_task_memory       = var.db_tools_task_memory
  db_tools_default_command   = var.db_tools_default_command
  backend_container_port     = var.backend_container_port
  backend_task_cpu           = var.backend_task_cpu
  backend_task_memory        = var.backend_task_memory
  backend_desired_count      = var.backend_desired_count
  backend_environment        = local.backend_environment
  redis_container_image      = local.redis_container_image
  redis_port                 = var.redis_port
  redis_task_cpu             = var.redis_task_cpu
  redis_task_memory          = var.redis_task_memory
  redis_desired_count        = var.redis_desired_count
  db_name                    = var.db_name
  db_username                = var.db_username
  db_instance_class          = var.db_instance_class
  db_allocated_storage       = var.db_allocated_storage
  db_engine_version          = var.db_engine_version
  db_backup_retention_period = var.db_backup_retention_period
  enable_execute_command     = var.enable_execute_command
  log_retention_in_days      = var.log_retention_in_days
  front_domain_name          = local.front_domain_name
  front_certificate_arn      = local.front_certificate_arn
  api_domain_name            = local.api_domain_name
  route53_zone_id            = local.route53_zone_id
  alb_certificate_arn        = local.alb_certificate_arn
  alb_ssl_policy             = var.alb_ssl_policy
}
