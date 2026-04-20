output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_db_subnet_ids" {
  value = module.network.private_db_subnet_ids
}

output "alb_security_group_id" {
  value = module.network.alb_security_group_id
}

output "app_security_group_id" {
  value = module.network.app_security_group_id
}

output "db_security_group_id" {
  value = module.network.db_security_group_id
}

output "redis_security_group_id" {
  value = module.network.redis_security_group_id
}

output "app_target_group_arn" {
  value = module.network.app_target_group_arn
}

output "ecr_api_vpc_endpoint_id" {
  value = module.network.ecr_api_vpc_endpoint_id
}

output "ecr_dkr_vpc_endpoint_id" {
  value = module.network.ecr_dkr_vpc_endpoint_id
}
