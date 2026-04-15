locals {
  backend_log_group_name = "/ecs/${local.deploy_name}-backend"
  redis_log_group_name   = "/ecs/${local.deploy_name}-redis"

  redis_discovery_namespace = "${local.deploy_name}.local"

  backend_runtime_environment = merge(
    var.backend_environment,
    // DB関連はデプロイ時でないと決まらないのでこのタイミングで設定する。
    {
      DB_SECRET_NAME = data.aws_secretsmanager_secret.db_master.name
      DB_HOST    = aws_db_instance.main.address
      DB_PORT    = tostring(aws_db_instance.main.port)
      DB_NAME    = aws_db_instance.main.db_name
      REDIS_HOST = "redis.${aws_service_discovery_private_dns_namespace.redis.name}"
      REDIS_PORT = tostring(var.redis_port)
    }
  )
}

data "aws_secretsmanager_secret" "db_master" {
  arn = aws_db_instance.main.master_user_secret[0].secret_arn
}

data "aws_subnet" "private_db" {
  for_each = toset(var.private_db_subnet_ids)
  id       = each.value
}

resource "aws_service_discovery_private_dns_namespace" "redis" {
  name = local.redis_discovery_namespace
  vpc  = var.vpc_id

  tags = local.common_tags
}

resource "aws_service_discovery_service" "redis" {
  name = "redis"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.redis.id

    dns_records {
      type = "A"
      ttl  = 10
    }

    routing_policy = "MULTIVALUE"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${local.deploy_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = local.backend_log_group_name
  retention_in_days = var.log_retention_in_days
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "redis" {
  name              = local.redis_log_group_name
  retention_in_days = var.log_retention_in_days
  tags              = local.common_tags
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${local.deploy_name}-backend"
  cpu                      = var.backend_task_cpu
  memory                   = var.backend_task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.backend_container_image
      essential = true
      portMappings = [
        {
          name          = "http"
          containerPort = var.backend_container_port
          hostPort      = var.backend_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        for k, v in local.backend_runtime_environment : {
          name  = k
          value = v
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "backend"
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

resource "aws_ecs_task_definition" "redis" {
  family                   = "${local.deploy_name}-redis"
  cpu                      = var.redis_task_cpu
  memory                   = var.redis_task_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "redis"
      image     = var.redis_container_image
      essential = true
      command   = ["redis-server", "--appendonly", "no"]
      portMappings = [
        {
          name          = "redis"
          containerPort = var.redis_port
          hostPort      = var.redis_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.redis.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "redis"
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

resource "aws_ecs_service" "backend" {
  name            = "${local.deploy_name}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count
  launch_type     = "FARGATE"

  enable_execute_command            = var.enable_execute_command
  health_check_grace_period_seconds = 60

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "backend"
    container_port   = var.backend_container_port
  }

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.app_security_group_id]
    assign_public_ip = true
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  enable_ecs_managed_tags = true
  propagate_tags          = "TASK_DEFINITION"

  tags = local.common_tags
}

resource "aws_ecs_service" "redis" {
  name            = "${local.deploy_name}-redis"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.redis.arn
  desired_count   = var.redis_desired_count
  launch_type     = "FARGATE"

  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets          = [for subnet in data.aws_subnet.private_db : subnet.id if subnet.availability_zone == "${var.aws_region}a"]
    security_groups  = [var.redis_security_group_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.redis.arn
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  enable_ecs_managed_tags = true
  propagate_tags          = "TASK_DEFINITION"

  tags = local.common_tags
}
