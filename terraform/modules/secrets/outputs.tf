output "all_parameter_arns" {
  description = "List of all SSM parameter ARNs"
  value = [
    aws_ssm_parameter.core_db_host.arn,
    aws_ssm_parameter.core_db_name.arn,
    aws_ssm_parameter.core_db_username.arn,
    aws_ssm_parameter.core_db_password.arn,
    aws_ssm_parameter.core_db_port.arn,
    aws_ssm_parameter.deployment_db_host.arn,
    aws_ssm_parameter.deployment_db_name.arn,
    aws_ssm_parameter.deployment_db_username.arn,
    aws_ssm_parameter.deployment_db_password.arn,
    aws_ssm_parameter.deployment_db_port.arn,
    aws_ssm_parameter.flask_secret_key.arn,
  ]
}

output "core_parameter_names" {
  description = "Map of SSM parameter names for core-service"
  value = {
    db_host          = aws_ssm_parameter.core_db_host.name
    db_name          = aws_ssm_parameter.core_db_name.name
    db_username      = aws_ssm_parameter.core_db_username.name
    db_password      = aws_ssm_parameter.core_db_password.name
    db_port          = aws_ssm_parameter.core_db_port.name
    flask_secret_key = aws_ssm_parameter.flask_secret_key.name
  }
}

output "deployment_parameter_names" {
  description = "Map of SSM parameter names for deployment-service"
  value = {
    db_host          = aws_ssm_parameter.deployment_db_host.name
    db_name          = aws_ssm_parameter.deployment_db_name.name
    db_username      = aws_ssm_parameter.deployment_db_username.name
    db_password      = aws_ssm_parameter.deployment_db_password.name
    db_port          = aws_ssm_parameter.deployment_db_port.name
    flask_secret_key = aws_ssm_parameter.flask_secret_key.name
  }
}
