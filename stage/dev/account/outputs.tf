output "oidc_provider_arn" {
  value = module.account.oidc_provider_arn
}

output "cicd_role_arn" {
  value = module.account.cicd_role_arn
}

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

output "backend_ecr_repository_arn" {
  value = module.account.backend_ecr_repository_arn
}

output "ecr_repository_urls" {
  value = module.account.ecr_repository_urls
}

output "ecr_repository_arns" {
  value = module.account.ecr_repository_arns
}

output "ecs_task_execution_role_arn" {
  value = module.account.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  value = module.account.ecs_task_role_arn
}
