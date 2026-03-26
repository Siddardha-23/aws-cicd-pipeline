################################################################################
# Flask Secret Key
################################################################################

resource "random_password" "flask_secret" {
  length  = 32
  special = true
}

################################################################################
# Core Service SSM Parameters
################################################################################

resource "aws_ssm_parameter" "core_db_host" {
  name  = "/opsboard/core/db-host"
  type  = "String"
  value = var.db_host

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-core-db-host"
  })
}

resource "aws_ssm_parameter" "core_db_name" {
  name  = "/opsboard/core/db-name"
  type  = "String"
  value = var.core_db_name

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-core-db-name"
  })
}

resource "aws_ssm_parameter" "core_db_username" {
  name  = "/opsboard/core/db-username"
  type  = "String"
  value = var.db_username

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-core-db-username"
  })
}

resource "aws_ssm_parameter" "core_db_password" {
  name  = "/opsboard/core/db-password"
  type  = "SecureString"
  value = var.db_password

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-core-db-password"
  })
}

resource "aws_ssm_parameter" "core_db_port" {
  name  = "/opsboard/core/db-port"
  type  = "String"
  value = var.db_port

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-core-db-port"
  })
}

################################################################################
# Deployment Service SSM Parameters
################################################################################

resource "aws_ssm_parameter" "deployment_db_host" {
  name  = "/opsboard/deployment/db-host"
  type  = "String"
  value = var.db_host

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-deployment-db-host"
  })
}

resource "aws_ssm_parameter" "deployment_db_name" {
  name  = "/opsboard/deployment/db-name"
  type  = "String"
  value = var.deployment_db_name

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-deployment-db-name"
  })
}

resource "aws_ssm_parameter" "deployment_db_username" {
  name  = "/opsboard/deployment/db-username"
  type  = "String"
  value = var.db_username

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-deployment-db-username"
  })
}

resource "aws_ssm_parameter" "deployment_db_password" {
  name  = "/opsboard/deployment/db-password"
  type  = "SecureString"
  value = var.db_password

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-deployment-db-password"
  })
}

resource "aws_ssm_parameter" "deployment_db_port" {
  name  = "/opsboard/deployment/db-port"
  type  = "String"
  value = var.db_port

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-deployment-db-port"
  })
}

################################################################################
# Shared Flask Secret Key
################################################################################

resource "aws_ssm_parameter" "flask_secret_key" {
  name  = "/opsboard/production/flask-secret-key"
  type  = "SecureString"
  value = random_password.flask_secret.result

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-flask-secret-key"
  })
}
