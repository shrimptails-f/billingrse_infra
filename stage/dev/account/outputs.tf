output "oidc_provider_arn" {
  value = module.account.oidc_provider_arn
}

output "cicd_role_arn" {
  value = module.account.cicd_role_arn
}

output "backend_ecr_repository_url" {
  value = module.account.backend_ecr_repository_url
}

output "backend_ecr_repository_arn" {
  value = module.account.backend_ecr_repository_arn
}

output "ecs_task_execution_role_arn" {
  value = module.account.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  value = module.account.ecs_task_role_arn
}
