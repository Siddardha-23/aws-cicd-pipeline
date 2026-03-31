################################################################################
# Frontend ECR Repository
################################################################################

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.name_prefix}-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-frontend"
  })
}

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

################################################################################
# Core Service ECR Repository
################################################################################

resource "aws_ecr_repository" "core" {
  name                 = "${var.name_prefix}-core"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-core"
  })
}

resource "aws_ecr_lifecycle_policy" "core" {
  repository = aws_ecr_repository.core.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

################################################################################
# Deployment Service ECR Repository
################################################################################

resource "aws_ecr_repository" "deployment" {
  name                 = "${var.name_prefix}-deployment"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-deployment"
  })
}

resource "aws_ecr_lifecycle_policy" "deployment" {
  repository = aws_ecr_repository.deployment.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

################################################################################
# Initial Image Push (builds and pushes app images on first terraform apply)
################################################################################

resource "null_resource" "initial_image_push" {
  # Re-run only if ECR repos are recreated
  triggers = {
    frontend_repo   = aws_ecr_repository.frontend.repository_url
    core_repo       = aws_ecr_repository.core.repository_url
    deployment_repo = aws_ecr_repository.deployment.repository_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e

      REGION="${var.aws_region}"
      FRONTEND_REPO="${aws_ecr_repository.frontend.repository_url}"
      CORE_REPO="${aws_ecr_repository.core.repository_url}"
      DEPLOYMENT_REPO="${aws_ecr_repository.deployment.repository_url}"
      ECR_REGISTRY="${split("/", aws_ecr_repository.frontend.repository_url)[0]}"
      SOURCE="${var.source_path}"

      echo "Logging into ECR..."
      aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

      echo "Building and pushing frontend..."
      docker build -t $FRONTEND_REPO:latest $SOURCE/frontend/
      docker push $FRONTEND_REPO:latest

      echo "Building and pushing core-service..."
      docker build -t $CORE_REPO:latest $SOURCE/services/core-service/
      docker push $CORE_REPO:latest

      echo "Building and pushing deployment-service..."
      docker build -t $DEPLOYMENT_REPO:latest $SOURCE/services/deployment-service/
      docker push $DEPLOYMENT_REPO:latest

      echo "All images pushed successfully!"
    EOT
  }

  depends_on = [
    aws_ecr_repository.frontend,
    aws_ecr_repository.core,
    aws_ecr_repository.deployment,
  ]
}
