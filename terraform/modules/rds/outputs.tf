output "db_endpoint" {
  description = "RDS instance endpoint (hostname only)"
  value       = aws_db_instance.main.address
}

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Master username"
  value       = aws_db_instance.main.username
}

output "db_password" {
  description = "Master password"
  value       = random_password.db.result
  sensitive   = true
}

output "db_port" {
  description = "Database port"
  value       = tostring(aws_db_instance.main.port)
}
