################################################################################
# CodeStar Connection
################################################################################

resource "aws_codestarconnections_connection" "github" {
  name          = "opsboard-github"
  provider_type = "GitHub"

  tags = merge(var.common_tags, {
    Name = "opsboard-github"
  })
}

################################################################################
# Artifact S3 Bucket
################################################################################

resource "aws_s3_bucket" "artifacts" {
  bucket_prefix = "${var.name_prefix}-artifacts-"
  force_destroy = true

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-pipeline-artifacts"
  })
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

################################################################################
# CodeBuild IAM Role
################################################################################

data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name = "${var.name_prefix}-codebuild-role"

  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-codebuild-role"
  })
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    sid = "ECRAccess"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = ["*"]
  }

  statement {
    sid = "CloudWatchLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  statement {
    sid = "S3Artifacts"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
    ]
    resources = [
      aws_s3_bucket.artifacts.arn,
      "${aws_s3_bucket.artifacts.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "codebuild" {
  name   = "${var.name_prefix}-codebuild-policy"
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

################################################################################
# CodeBuild Projects (3 parallel builds)
################################################################################

resource "aws_codebuild_project" "frontend" {
  name         = "${var.name_prefix}-frontend-build"
  description  = "Build frontend Docker image"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.account_id
    }

    environment_variable {
      name  = "ECR_REPO_URI"
      value = var.frontend_ecr_repo_uri
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-frontend.yml"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-frontend-build"
  })
}

resource "aws_codebuild_project" "core" {
  name         = "${var.name_prefix}-core-build"
  description  = "Build core-service Docker image"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.account_id
    }

    environment_variable {
      name  = "ECR_REPO_URI"
      value = var.core_ecr_repo_uri
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-core.yml"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-core-build"
  })
}

resource "aws_codebuild_project" "deployment" {
  name         = "${var.name_prefix}-deployment-build"
  description  = "Build deployment-service Docker image"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.account_id
    }

    environment_variable {
      name  = "ECR_REPO_URI"
      value = var.deployment_ecr_repo_uri
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-deployment.yml"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-deployment-build"
  })
}

################################################################################
# CodeDeploy IAM Role
################################################################################

data "aws_iam_policy_document" "codedeploy_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name = "${var.name_prefix}-codedeploy-role"

  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume.json

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-codedeploy-role"
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_ecs" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

################################################################################
# CodeDeploy Applications and Deployment Groups
################################################################################

# --- Frontend ---
resource "aws_codedeploy_app" "frontend" {
  compute_platform = "ECS"
  name             = "${var.name_prefix}-frontend"
  tags             = var.common_tags
}

resource "aws_codedeploy_deployment_group" "frontend" {
  app_name               = aws_codedeploy_app.frontend.name
  deployment_group_name  = "${var.name_prefix}-frontend-dg"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.frontend_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.https_listener_arn]
      }
      test_traffic_route {
        listener_arns = [var.test_listener_arn]
      }
      target_group {
        name = var.frontend_blue_tg_name
      }
      target_group {
        name = var.frontend_green_tg_name
      }
    }
  }

  tags = var.common_tags
}

# --- Core Service ---
resource "aws_codedeploy_app" "core" {
  compute_platform = "ECS"
  name             = "${var.name_prefix}-core"
  tags             = var.common_tags
}

resource "aws_codedeploy_deployment_group" "core" {
  app_name               = aws_codedeploy_app.core.name
  deployment_group_name  = "${var.name_prefix}-core-dg"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.core_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.https_listener_arn]
      }
      test_traffic_route {
        listener_arns = [var.test_listener_arn]
      }
      target_group {
        name = var.core_blue_tg_name
      }
      target_group {
        name = var.core_green_tg_name
      }
    }
  }

  tags = var.common_tags
}

# --- Deployment Service ---
resource "aws_codedeploy_app" "deployment" {
  compute_platform = "ECS"
  name             = "${var.name_prefix}-deployment"
  tags             = var.common_tags
}

resource "aws_codedeploy_deployment_group" "deployment" {
  app_name               = aws_codedeploy_app.deployment.name
  deployment_group_name  = "${var.name_prefix}-deployment-dg"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.deployment_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.https_listener_arn]
      }
      test_traffic_route {
        listener_arns = [var.test_listener_arn]
      }
      target_group {
        name = var.deployment_blue_tg_name
      }
      target_group {
        name = var.deployment_green_tg_name
      }
    }
  }

  tags = var.common_tags
}

################################################################################
# CodePipeline IAM Role
################################################################################

data "aws_iam_policy_document" "pipeline_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pipeline" {
  name = "${var.name_prefix}-pipeline-role"

  assume_role_policy = data.aws_iam_policy_document.pipeline_assume.json

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-pipeline-role"
  })
}

data "aws_iam_policy_document" "pipeline_policy" {
  statement {
    sid       = "CodeStarConnection"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.github.arn]
  }

  statement {
    sid = "S3Artifacts"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:GetBucketVersioning",
    ]
    resources = [
      aws_s3_bucket.artifacts.arn,
      "${aws_s3_bucket.artifacts.arn}/*",
    ]
  }

  statement {
    sid = "CodeBuild"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]
    resources = [
      aws_codebuild_project.frontend.arn,
      aws_codebuild_project.core.arn,
      aws_codebuild_project.deployment.arn,
    ]
  }

  statement {
    sid = "CodeDeploy"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:RegisterApplicationRevision",
    ]
    resources = ["*"]
  }

  statement {
    sid = "ECS"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeServices",
      "ecs:UpdateService",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "IAMPassRole"
    actions   = ["iam:PassRole"]
    resources = ["*"]
    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "pipeline" {
  name   = "${var.name_prefix}-pipeline-policy"
  role   = aws_iam_role.pipeline.id
  policy = data.aws_iam_policy_document.pipeline_policy.json
}

################################################################################
# CodePipeline (3 parallel builds, 3 sequential deploys)
################################################################################

resource "aws_codepipeline" "main" {
  name     = "${var.name_prefix}-pipeline"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repo
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "frontend-build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["frontend_build_output"]
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.frontend.name
      }
    }

    action {
      name             = "core-build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["core_build_output"]
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.core.name
      }
    }

    action {
      name             = "deployment-build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["deployment_build_output"]
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.deployment.name
      }
    }
  }

  stage {
    name = "Deploy"

    # Deploy deployment-service first (core-service depends on it)
    action {
      name            = "deploy-deployment"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["deployment_build_output", "source_output"]
      run_order       = 1

      configuration = {
        ApplicationName                = aws_codedeploy_app.deployment.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.deployment.deployment_group_name
        AppSpecTemplateArtifact        = "source_output"
        AppSpecTemplatePath            = "codedeploy/appspec-deployment.yaml"
        TaskDefinitionTemplateArtifact = "source_output"
        TaskDefinitionTemplatePath     = "codedeploy/taskdef-deployment.json"
        Image1ArtifactName             = "deployment_build_output"
        Image1ContainerName            = "IMAGE1_NAME"
      }
    }

    # Deploy core-service after deployment-service is healthy
    action {
      name            = "deploy-core"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["core_build_output", "source_output"]
      run_order       = 2

      configuration = {
        ApplicationName                = aws_codedeploy_app.core.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.core.deployment_group_name
        AppSpecTemplateArtifact        = "source_output"
        AppSpecTemplatePath            = "codedeploy/appspec-core.yaml"
        TaskDefinitionTemplateArtifact = "source_output"
        TaskDefinitionTemplatePath     = "codedeploy/taskdef-core.json"
        Image1ArtifactName             = "core_build_output"
        Image1ContainerName            = "IMAGE1_NAME"
      }
    }

    # Deploy frontend last
    action {
      name            = "deploy-frontend"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["frontend_build_output", "source_output"]
      run_order       = 3

      configuration = {
        ApplicationName                = aws_codedeploy_app.frontend.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.frontend.deployment_group_name
        AppSpecTemplateArtifact        = "source_output"
        AppSpecTemplatePath            = "codedeploy/appspec-frontend.yaml"
        TaskDefinitionTemplateArtifact = "source_output"
        TaskDefinitionTemplatePath     = "codedeploy/taskdef-frontend.json"
        Image1ArtifactName             = "frontend_build_output"
        Image1ContainerName            = "IMAGE1_NAME"
      }
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-pipeline"
  })
}
