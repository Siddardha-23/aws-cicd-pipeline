output "parameter_arns" {
  description = "List of all SSM parameter ARNs"
  value = [
    aws_ssm_parameter.db_host.arn,
    aws_ssm_parameter.db_name.arn,
    aws_ssm_parameter.db_username.arn,
    aws_ssm_parameter.db_password.arn,
    aws_ssm_parameter.db_port.arn,
    aws_ssm_parameter.flask_secret_key.arn,
  ]
}

output "parameter_names" {
  description = "Map of SSM parameter names"
  value = {
    db_host          = aws_ssm_parameter.db_host.name
    db_name          = aws_ssm_parameter.db_name.name
    db_username      = aws_ssm_parameter.db_username.name
    db_password      = aws_ssm_parameter.db_password.name
    db_port          = aws_ssm_parameter.db_port.name
    flask_secret_key = aws_ssm_parameter.flask_secret_key.name
  }
}
