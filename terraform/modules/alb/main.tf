################################################################################
# Application Load Balancer
################################################################################

resource "aws_lb" "main" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-alb"
  })
}

################################################################################
# Frontend Target Groups (Blue/Green)
################################################################################

resource "aws_lb_target_group" "frontend_blue" {
  name                 = "${var.name_prefix}-fe-blue"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-frontend-blue"
  })
}

resource "aws_lb_target_group" "frontend_green" {
  name                 = "${var.name_prefix}-fe-green"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-frontend-green"
  })
}

################################################################################
# Core Service Target Groups (Blue/Green)
################################################################################

resource "aws_lb_target_group" "core_blue" {
  name                 = "${var.name_prefix}-core-blue"
  port                 = 5000
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/api/v1/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-core-blue"
  })
}

resource "aws_lb_target_group" "core_green" {
  name                 = "${var.name_prefix}-core-grn"
  port                 = 5000
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/api/v1/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-core-green"
  })
}

################################################################################
# Deployment Service Target Groups (Blue/Green)
################################################################################

resource "aws_lb_target_group" "deployment_blue" {
  name                 = "${var.name_prefix}-dep-blue"
  port                 = 5001
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/api/v1/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-deployment-blue"
  })
}

resource "aws_lb_target_group" "deployment_green" {
  name                 = "${var.name_prefix}-dep-green"
  port                 = 5001
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/api/v1/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-deployment-green"
  })
}

################################################################################
# HTTPS Listener (443)
################################################################################

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_blue.arn
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-https-listener"
  })
}

# Priority 90: /api/v1/deployments* → deployment-service (evaluated first)
resource "aws_lb_listener_rule" "https_deployments" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 90

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deployment_blue.arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/deployments", "/api/v1/deployments/*"]
    }
  }

  tags = var.common_tags
}

# Priority 100: /api/* → core-service (catch-all for remaining API routes)
resource "aws_lb_listener_rule" "https_core" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core_blue.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  tags = var.common_tags
}

################################################################################
# HTTP Listener (80) - Redirect to HTTPS
################################################################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-http-listener"
  })
}

################################################################################
# Test Listener (8443) - For CodeDeploy Blue/Green
################################################################################

resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.main.arn
  port              = 8443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_green.arn
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-test-listener"
  })
}

resource "aws_lb_listener_rule" "test_deployments" {
  listener_arn = aws_lb_listener.test.arn
  priority     = 90

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deployment_green.arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/deployments", "/api/v1/deployments/*"]
    }
  }

  tags = var.common_tags
}

resource "aws_lb_listener_rule" "test_core" {
  listener_arn = aws_lb_listener.test.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core_green.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  tags = var.common_tags
}
