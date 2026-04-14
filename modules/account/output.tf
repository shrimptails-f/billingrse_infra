output "backend_ecr_repository_url" {
  value = aws_ecr_repository.this[var.backend_ecr_repository_name].repository_url
}

output "backend_ecr_repository_arn" {
  value = aws_ecr_repository.this[var.backend_ecr_repository_name].arn
}

output "ecr_repository_urls" {
  value = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "ecr_repository_arns" {
  value = { for name, repo in aws_ecr_repository.this : name => repo.arn }
}

output "oidc_provider_arn" {
  value = local.github_actions_oidc_provider_arn
}

output "cicd_role_arn" {
  value = aws_iam_role.infra_cicd.arn
}

output "infra_cicd_role_arn" {
  value = aws_iam_role.infra_cicd.arn
}

output "backend_cicd_role_arn" {
  value = aws_iam_role.backend_cicd.arn
}

output "front_cicd_role_arn" {
  value = aws_iam_role.front_cicd.arn
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}
