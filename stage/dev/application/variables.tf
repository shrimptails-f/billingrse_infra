variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "stage" {
  type    = string
  default = "dev"
}

variable "db_name" {
  type    = string
  default = "development"
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

variable "backend_container_image" {
  type    = string
  default = ""
}

variable "backend_image_tag" {
  type    = string
  default = "latest"
}

variable "redis_container_image" {
  type    = string
  default = ""
}

variable "db_init_image" {
  type    = string
  default = ""
}

variable "db_tools_image" {
  type    = string
  default = ""
}

variable "redis_repository_name" {
  type    = string
  default = "billingrse-dev-redis"
}

variable "db_init_repository_name" {
  type    = string
  default = "billingrse-dev-db-init"
}

variable "db_tools_repository_name" {
  type    = string
  default = "billingrse-dev-db-tools"
}

variable "redis_image_tag" {
  type    = string
  default = "latest"
}

variable "db_init_image_tag" {
  type    = string
  default = "latest"
}

variable "db_tools_image_tag" {
  type    = string
  default = "latest"
}

variable "db_init_secret_name" {
  type    = string
  default = "billingrse_dev"
}

variable "db_init_mysql_database" {
  type    = string
  default = "development"
}

variable "db_init_task_role_arn" {
  type    = string
  default = null
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

variable "enable_execute_command" {
  type    = bool
  default = true
}

variable "log_retention_in_days" {
  type    = number
  default = 14
}

variable "backend_environment" {
  type    = map(string)
  default = {}
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
