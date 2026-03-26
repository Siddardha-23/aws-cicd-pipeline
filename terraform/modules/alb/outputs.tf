output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = aws_lb.main.zone_id
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB for CloudWatch metrics"
  value       = aws_lb.main.arn_suffix
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = aws_lb_listener.https.arn
}

output "test_listener_arn" {
  description = "ARN of the test listener"
  value       = aws_lb_listener.test.arn
}

# Frontend target groups
output "frontend_blue_tg_arn" {
  value = aws_lb_target_group.frontend_blue.arn
}
output "frontend_green_tg_arn" {
  value = aws_lb_target_group.frontend_green.arn
}
output "frontend_blue_tg_name" {
  value = aws_lb_target_group.frontend_blue.name
}
output "frontend_green_tg_name" {
  value = aws_lb_target_group.frontend_green.name
}
output "frontend_blue_tg_arn_suffix" {
  value = aws_lb_target_group.frontend_blue.arn_suffix
}

# Core service target groups
output "core_blue_tg_arn" {
  value = aws_lb_target_group.core_blue.arn
}
output "core_green_tg_arn" {
  value = aws_lb_target_group.core_green.arn
}
output "core_blue_tg_name" {
  value = aws_lb_target_group.core_blue.name
}
output "core_green_tg_name" {
  value = aws_lb_target_group.core_green.name
}
output "core_blue_tg_arn_suffix" {
  value = aws_lb_target_group.core_blue.arn_suffix
}

# Deployment service target groups
output "deployment_blue_tg_arn" {
  value = aws_lb_target_group.deployment_blue.arn
}
output "deployment_green_tg_arn" {
  value = aws_lb_target_group.deployment_green.arn
}
output "deployment_blue_tg_name" {
  value = aws_lb_target_group.deployment_blue.name
}
output "deployment_green_tg_name" {
  value = aws_lb_target_group.deployment_green.name
}
output "deployment_blue_tg_arn_suffix" {
  value = aws_lb_target_group.deployment_blue.arn_suffix
}
