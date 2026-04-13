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
    key            = "network/terraform.tfstate"
    encrypt        = true
  }
}

module "common" {
  source = "../../common"
}

module "dev" {
  source = "../"
}

locals {
  vpc_cidr_block = "10.0.0.0/20"

  public_subnet_cidrs = {
    a = "10.0.0.0/24"
  }

  private_db_subnet_cidrs = {
    a = "10.0.1.0/24"
  }
}

provider "aws" {
  region = module.common.aws_region
}

module "network" {
  source = "../../../modules/network"

  aws_region              = module.common.aws_region
  stage                   = module.dev.stage
  vpc_cidr_block          = local.vpc_cidr_block
  public_subnet_cidrs     = local.public_subnet_cidrs
  private_db_subnet_cidrs = local.private_db_subnet_cidrs
}
