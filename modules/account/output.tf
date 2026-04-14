output "backend_ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "backend_ecr_repository_arn" {
  value = aws_ecr_repository.backend.arn
}

output "oidc_provider_arn" {
  value = local.github_actions_oidc_provider_arn
}

output "cicd_role_arn" {
  value = aws_iam_role.cicd.arn
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}
