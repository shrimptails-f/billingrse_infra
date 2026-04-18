variable "aws_region" {
  type = string
}

variable "stage" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_db_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "app_security_group_id" {
  type = string
}

variable "db_security_group_id" {
  type = string
}

variable "redis_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "task_execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "db_init_task_role_arn" {
  type    = string
  default = null
}

variable "backend_container_image" {
  type = string
}

variable "backend_container_port" {
  type    = number
  default = 8080
}

variable "backend_task_cpu" {
  type    = number
  default = 256
}

variable "backend_task_memory" {
  type    = number
  default = 512
}

variable "backend_desired_count" {
  type    = number
  default = 1
}

variable "backend_environment" {
  type    = map(string)
  default = {}
}

variable "redis_container_image" {
  type = string
}

variable "db_init_image" {
  type = string
}

variable "db_init_secret_name" {
  type    = string
  default = "billingrse_dev"
}

variable "db_init_mysql_database" {
  type    = string
  default = "development"
}

variable "db_tools_image" {
  type = string
}

variable "db_tools_task_cpu" {
  type    = number
  default = 256
}

variable "db_tools_task_memory" {
  type    = number
  default = 512
}

variable "db_tools_default_command" {
  type    = list(string)
  default = ["sh", "-c", "sleep 3600"]
}

variable "redis_port" {
  type    = number
  default = 6379
}

variable "redis_task_cpu" {
  type    = number
  default = 256
}

variable "redis_task_memory" {
  type    = number
  default = 512
}

variable "redis_desired_count" {
  type    = number
  default = 1
}

variable "db_name" {
  type    = string
  default = "app"
}

variable "db_username" {
  type = string
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_engine_version" {
  type    = string
  default = "8.4.3"
}

variable "db_backup_retention_period" {
  type    = number
  default = 7
}

variable "enable_execute_command" {
  type    = bool
  default = true
}

variable "log_retention_in_days" {
  type    = number
  default = 14
}

variable "front_domain_name" {
  type    = string
  default = ""
}

variable "front_certificate_arn" {
  type    = string
  default = ""
}

variable "api_domain_name" {
  type    = string
  default = ""
}

variable "route53_zone_id" {
  type    = string
  default = ""
}

variable "alb_certificate_arn" {
  type    = string
  default = ""
}

variable "alb_ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-2016-08"
}

locals {
  project_name = "billingrse"
  deploy_name  = "${local.project_name}-${var.stage}"
  common_tags = {
    Project = local.project_name
    Managed = "terraform"
    Stage   = var.stage
  }

  front_bucket_name = "${local.deploy_name}-front"
}
