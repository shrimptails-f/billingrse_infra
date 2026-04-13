variable "aws_region" {
  type = string
}

variable "stage" {
  type = string
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

# VPC関連
variable "vpc_cidr_block" {
  type = string
}

variable "public_subnet_cidrs" {
  type = map(string)
}

variable "private_db_subnet_cidrs" {
  type = map(string)
}
