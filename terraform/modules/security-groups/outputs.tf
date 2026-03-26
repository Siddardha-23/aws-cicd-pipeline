output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "frontend_sg_id" {
  description = "ID of the frontend security group"
  value       = aws_security_group.frontend.id
}

output "core_sg_id" {
  description = "ID of the core-service security group"
  value       = aws_security_group.core.id
}

output "deployment_sg_id" {
  description = "ID of the deployment-service security group"
  value       = aws_security_group.deployment.id
}

output "rds_sg_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}
