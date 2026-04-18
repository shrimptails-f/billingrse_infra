output "infra_cicd_role_arn" {
  value = module.account.infra_cicd_role_arn
}

output "backend_cicd_role_arn" {
  value = module.account.backend_cicd_role_arn
}

output "front_cicd_role_arn" {
  value = module.account.front_cicd_role_arn
}

output "backend_ecr_repository_url" {
  value = module.account.backend_ecr_repository_url
}

output "ecr_repository_urls" {
  value = module.account.ecr_repository_urls
}

output "ecs_task_execution_role_arn" {
  value = module.account.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  value = module.account.ecs_task_role_arn
}
