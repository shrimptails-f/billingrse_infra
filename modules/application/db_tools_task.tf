locals {
  db_tools_log_group_name = "/ecs/${local.deploy_name}-db-tools"
  db_port                 = aws_db_instance.main.port
}

resource "aws_cloudwatch_log_group" "db_tools" {
  name              = local.db_tools_log_group_name
  retention_in_days = var.log_retention_in_days
  tags              = local.common_tags
}

resource "aws_ecs_task_definition" "db_tools" {
  family                   = "${local.deploy_name}-db-tools"
  cpu                      = var.db_tools_task_cpu
  memory                   = var.db_tools_task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "db-tools"
      image     = var.db_tools_image
      essential = true
      command   = var.db_tools_default_command
      environment = [
        { name = "DB_HOST", value = local.db_host },
        { name = "DB_PORT", value = tostring(local.db_port) },
        { name = "IS_HIDDEN_SQL", value = "false" },
        { name = "MYSQL_DATABASE", value = var.db_init_mysql_database },
        { name = "MIGRATION_STAGE", value = "dev" },
      ]
      secrets = [
        { name = "MYSQL_USER", valueFrom = "${data.aws_secretsmanager_secret.db_init.arn}:MYSQL_USER::" },
        { name = "MYSQL_PASSWORD", valueFrom = "${data.aws_secretsmanager_secret.db_init.arn}:MYSQL_PASSWORD::" },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.db_tools.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "db-tools"
        }
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = local.common_tags
}
