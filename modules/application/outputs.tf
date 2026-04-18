output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "backend_service_name" {
  value = aws_ecs_service.backend.name
}

output "backend_task_definition_arn" {
  value = aws_ecs_task_definition.backend.arn
}

output "db_init_task_definition_arn" {
  value = aws_ecs_task_definition.db_init.arn
}

output "db_tools_task_definition_arn" {
  value = aws_ecs_task_definition.db_tools.arn
}

output "redis_service_name" {
  value = aws_ecs_service.redis.name
}

output "redis_task_definition_arn" {
  value = aws_ecs_task_definition.redis.arn
}

output "redis_discovery_fqdn" {
  value = "redis.${aws_service_discovery_private_dns_namespace.redis.name}"
}

output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_address" {
  value = aws_db_instance.main.address
}

output "db_port" {
  value = aws_db_instance.main.port
}

output "db_master_secret_arn" {
  value = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "front_bucket_name" {
  value = aws_s3_bucket.front.bucket
}

output "front_cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.front.id
}

output "front_cloudfront_domain_name" {
  value = aws_cloudfront_distribution.front.domain_name
}
