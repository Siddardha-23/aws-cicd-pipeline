################################################################################
# ECS Cluster
################################################################################

resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-cluster"
  })
}

################################################################################
# Cloud Map Service Discovery
################################################################################

resource "aws_service_discovery_private_dns_namespace" "main" {
  name = "opsboard.local"
  vpc  = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-service-discovery"
  })
}

resource "aws_service_discovery_service" "deployment" {
  name = "deployment-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = var.common_tags
}

################################################################################
# CloudWatch Log Groups
################################################################################

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.name_prefix}-frontend"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-frontend-logs"
  })
}

resource "aws_cloudwatch_log_group" "core" {
  name              = "/ecs/${var.name_prefix}-core"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-core-logs"
  })
}

resource "aws_cloudwatch_log_group" "deployment" {
  name              = "/ecs/${var.name_prefix}-deployment"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-deployment-logs"
  })
}

################################################################################
# Task Execution IAM Role
################################################################################

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name = "${var.name_prefix}-task-execution-role"

  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-task-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_base" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "task_execution_custom" {
  statement {
    sid = "SSMGetParameters"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
    ]
    resources = var.ssm_parameter_arns
  }

  statement {
    sid = "CloudWatchLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.frontend.arn}:*",
      "${aws_cloudwatch_log_group.core.arn}:*",
      "${aws_cloudwatch_log_group.deployment.arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "task_execution_custom" {
  name   = "${var.name_prefix}-task-execution-custom"
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.task_execution_custom.json
}

################################################################################
# Task IAM Role
################################################################################

resource "aws_iam_role" "task" {
  name = "${var.name_prefix}-task-role"

  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-task-role"
  })
}

################################################################################
# Frontend Task Definition
################################################################################

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.name_prefix}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${var.frontend_repo_url}:PLACEHOLDER"
      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-frontend-task"
  })
}

################################################################################
# Core Service Task Definition
################################################################################

resource "aws_ecs_task_definition" "core" {
  family                   = "${var.name_prefix}-core"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "core"
      image     = "${var.core_repo_url}:PLACEHOLDER"
      essential = true

      portMappings = [
        {
          containerPort = 5000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "FLASK_ENV"
          value = "production"
        },
        {
          name  = "DEPLOYMENT_SERVICE_URL"
          value = "http://deployment-service.opsboard.local:5001"
        }
      ]

      secrets = [
        {
          name      = "DB_HOST"
          valueFrom = var.core_ssm_parameter_names["db_host"]
        },
        {
          name      = "DB_NAME"
          valueFrom = var.core_ssm_parameter_names["db_name"]
        },
        {
          name      = "DB_USERNAME"
          valueFrom = var.core_ssm_parameter_names["db_username"]
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = var.core_ssm_parameter_names["db_password"]
        },
        {
          name      = "DB_PORT"
          valueFrom = var.core_ssm_parameter_names["db_port"]
        },
        {
          name      = "FLASK_SECRET_KEY"
          valueFrom = var.core_ssm_parameter_names["flask_secret_key"]
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:5000/api/v1/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.core.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-core-task"
  })
}

################################################################################
# Deployment Service Task Definition
################################################################################

resource "aws_ecs_task_definition" "deployment" {
  family                   = "${var.name_prefix}-deployment"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "deployment"
      image     = "${var.deployment_repo_url}:PLACEHOLDER"
      essential = true

      portMappings = [
        {
          containerPort = 5001
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "FLASK_ENV"
          value = "production"
        }
      ]

      secrets = [
        {
          name      = "DB_HOST"
          valueFrom = var.deployment_ssm_parameter_names["db_host"]
        },
        {
          name      = "DB_NAME"
          valueFrom = var.deployment_ssm_parameter_names["db_name"]
        },
        {
          name      = "DB_USERNAME"
          valueFrom = var.deployment_ssm_parameter_names["db_username"]
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = var.deployment_ssm_parameter_names["db_password"]
        },
        {
          name      = "DB_PORT"
          valueFrom = var.deployment_ssm_parameter_names["db_port"]
        },
        {
          name      = "FLASK_SECRET_KEY"
          valueFrom = var.deployment_ssm_parameter_names["flask_secret_key"]
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:5001/api/v1/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.deployment.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-deployment-task"
  })
}

################################################################################
# Database Migration Task Definitions
################################################################################

resource "aws_ecs_task_definition" "core_migration" {
  family                   = "${var.name_prefix}-core-migration"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "migration"
      image     = "${var.core_repo_url}:PLACEHOLDER"
      essential = true
      command   = ["./migrate.sh"]

      environment = [
        { name = "FLASK_ENV", value = "production" }
      ]

      secrets = [
        { name = "DB_HOST", valueFrom = var.core_ssm_parameter_names["db_host"] },
        { name = "DB_NAME", valueFrom = var.core_ssm_parameter_names["db_name"] },
        { name = "DB_USERNAME", valueFrom = var.core_ssm_parameter_names["db_username"] },
        { name = "DB_PASSWORD", valueFrom = var.core_ssm_parameter_names["db_password"] },
        { name = "DB_PORT", valueFrom = var.core_ssm_parameter_names["db_port"] },
        { name = "FLASK_SECRET_KEY", valueFrom = var.core_ssm_parameter_names["flask_secret_key"] }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.core.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "migration"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-core-migration-task"
  })
}

resource "aws_ecs_task_definition" "deployment_migration" {
  family                   = "${var.name_prefix}-deployment-migration"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "migration"
      image     = "${var.deployment_repo_url}:PLACEHOLDER"
      essential = true
      command   = ["./migrate.sh"]

      environment = [
        { name = "FLASK_ENV", value = "production" }
      ]

      secrets = [
        { name = "DB_HOST", valueFrom = var.deployment_ssm_parameter_names["db_host"] },
        { name = "DB_NAME", valueFrom = var.deployment_ssm_parameter_names["db_name"] },
        { name = "DB_USERNAME", valueFrom = var.deployment_ssm_parameter_names["db_username"] },
        { name = "DB_PASSWORD", valueFrom = var.deployment_ssm_parameter_names["db_password"] },
        { name = "DB_PORT", valueFrom = var.deployment_ssm_parameter_names["db_port"] },
        { name = "FLASK_SECRET_KEY", valueFrom = var.deployment_ssm_parameter_names["flask_secret_key"] }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.deployment.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "migration"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-deployment-migration-task"
  })
}

################################################################################
# Frontend ECS Service
################################################################################

resource "aws_ecs_service" "frontend" {
  name            = "${var.name_prefix}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.frontend_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.frontend_tg_arn
    container_name   = "frontend"
    container_port   = 80
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-frontend-service"
  })
}

################################################################################
# Core Service ECS Service
################################################################################

resource "aws_ecs_service" "core" {
  name            = "${var.name_prefix}-core"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.core.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.core_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.core_tg_arn
    container_name   = "core"
    container_port   = 5000
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-core-service"
  })
}

################################################################################
# Deployment Service ECS Service
################################################################################

resource "aws_ecs_service" "deployment" {
  name            = "${var.name_prefix}-deployment"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.deployment.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.deployment_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.deployment_tg_arn
    container_name   = "deployment"
    container_port   = 5001
  }

  service_registries {
    registry_arn = aws_service_discovery_service.deployment.arn
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-deployment-service"
  })
}
