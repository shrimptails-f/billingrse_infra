output "alb_dns_name" {
  value = module.application.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.application.ecs_cluster_name
}

output "backend_service_name" {
  value = module.application.backend_service_name
}

output "backend_task_definition_arn" {
  value = module.application.backend_task_definition_arn
}

output "redis_service_name" {
  value = module.application.redis_service_name
}

output "redis_task_definition_arn" {
  value = module.application.redis_task_definition_arn
}

output "redis_discovery_fqdn" {
  value = module.application.redis_discovery_fqdn
}

output "db_endpoint" {
  value = module.application.db_endpoint
}

output "db_address" {
  value = module.application.db_address
}

output "db_port" {
  value = module.application.db_port
}

output "db_master_secret_arn" {
  value = module.application.db_master_secret_arn
}

output "front_bucket_name" {
  value = module.application.front_bucket_name
}

output "front_cloudfront_distribution_id" {
  value = module.application.front_cloudfront_distribution_id
}

output "front_cloudfront_domain_name" {
  value = module.application.front_cloudfront_domain_name
}
