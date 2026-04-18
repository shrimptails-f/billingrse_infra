locals {
  db_init_task_role_arn  = coalesce(var.db_init_task_role_arn, var.task_role_arn)
  db_init_log_group_name = "/ecs/${local.deploy_name}-db-init"
}

data "aws_secretsmanager_secret" "db_init" {
  name = var.db_init_secret_name
}

resource "aws_cloudwatch_log_group" "db_init" {
  name              = local.db_init_log_group_name
  retention_in_days = var.log_retention_in_days
  tags              = local.common_tags
}

resource "aws_ecs_task_definition" "db_init" {
  family                   = "${local.deploy_name}-db-init"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = local.db_init_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "db-init"
      image     = var.db_init_image
      essential = true
      command = [
        "sh",
        "-c",
        "envsubst < /sql/init.sql | mysql -h\"$${DB_HOST}\" -u\"$${ADMIN_USER}\" -p\"$${ADMIN_PASSWORD}\" \"$${MYSQL_DATABASE}\""
      ]
      environment = [
        { name = "DB_HOST", value = local.db_host },
        { name = "MYSQL_DATABASE", value = var.db_init_mysql_database },
      ]
      secrets = [
        { name = "ADMIN_USER", valueFrom = "${local.db_master_secret_arn}:username::" },
        { name = "ADMIN_PASSWORD", valueFrom = "${local.db_master_secret_arn}:password::" },
        { name = "MYSQL_USER", valueFrom = "${data.aws_secretsmanager_secret.db_init.arn}:MYSQL_USER::" },
        { name = "MYSQL_PASSWORD", valueFrom = "${data.aws_secretsmanager_secret.db_init.arn}:MYSQL_PASSWORD::" },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.db_init.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "db-init"
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
