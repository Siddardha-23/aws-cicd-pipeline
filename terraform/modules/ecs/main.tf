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
# CloudWatch Log Groups
################################################################################

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.name_prefix}-frontend"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-frontend-logs"
  })
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.name_prefix}-backend"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-backend-logs"
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
      "${aws_cloudwatch_log_group.backend.arn}:*",
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
# Backend Task Definition
################################################################################

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.name_prefix}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${var.backend_repo_url}:PLACEHOLDER"
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
        }
      ]

      secrets = [
        {
          name      = "DB_HOST"
          valueFrom = var.ssm_parameter_names["db_host"]
        },
        {
          name      = "DB_NAME"
          valueFrom = var.ssm_parameter_names["db_name"]
        },
        {
          name      = "DB_USERNAME"
          valueFrom = var.ssm_parameter_names["db_username"]
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = var.ssm_parameter_names["db_password"]
        },
        {
          name      = "DB_PORT"
          valueFrom = var.ssm_parameter_names["db_port"]
        },
        {
          name      = "FLASK_SECRET_KEY"
          valueFrom = var.ssm_parameter_names["flask_secret_key"]
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
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-backend-task"
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
# Backend ECS Service
################################################################################

resource "aws_ecs_service" "backend" {
  name            = "${var.name_prefix}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.backend_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_tg_arn
    container_name   = "backend"
    container_port   = 5000
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-backend-service"
  })
}
