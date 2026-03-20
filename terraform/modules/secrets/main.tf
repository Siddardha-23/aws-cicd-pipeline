################################################################################
# Flask Secret Key
################################################################################

resource "random_password" "flask_secret" {
  length  = 32
  special = true
}

################################################################################
# SSM Parameters
################################################################################

resource "aws_ssm_parameter" "db_host" {
  name  = "/opsboard/db-host"
  type  = "String"
  value = var.db_host

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-host"
  })
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/opsboard/db-name"
  type  = "String"
  value = var.db_name

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-name"
  })
}

resource "aws_ssm_parameter" "db_username" {
  name  = "/opsboard/db-username"
  type  = "String"
  value = var.db_username

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-username"
  })
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/opsboard/db-password"
  type  = "SecureString"
  value = var.db_password

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-password"
  })
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/opsboard/db-port"
  type  = "String"
  value = var.db_port

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-port"
  })
}

resource "aws_ssm_parameter" "flask_secret_key" {
  name  = "/opsboard/flask-secret-key"
  type  = "SecureString"
  value = random_password.flask_secret.result

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-flask-secret-key"
  })
}
