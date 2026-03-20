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

output "frontend_blue_tg_arn" {
  description = "ARN of the frontend blue target group"
  value       = aws_lb_target_group.frontend_blue.arn
}

output "frontend_green_tg_arn" {
  description = "ARN of the frontend green target group"
  value       = aws_lb_target_group.frontend_green.arn
}

output "backend_blue_tg_arn" {
  description = "ARN of the backend blue target group"
  value       = aws_lb_target_group.backend_blue.arn
}

output "backend_green_tg_arn" {
  description = "ARN of the backend green target group"
  value       = aws_lb_target_group.backend_green.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = aws_lb_listener.https.arn
}

output "test_listener_arn" {
  description = "ARN of the test listener"
  value       = aws_lb_listener.test.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB for CloudWatch metrics"
  value       = aws_lb.main.arn_suffix
}

output "frontend_blue_tg_name" {
  description = "Name of the frontend blue target group"
  value       = aws_lb_target_group.frontend_blue.name
}

output "frontend_green_tg_name" {
  description = "Name of the frontend green target group"
  value       = aws_lb_target_group.frontend_green.name
}

output "backend_blue_tg_name" {
  description = "Name of the backend blue target group"
  value       = aws_lb_target_group.backend_blue.name
}

output "backend_green_tg_name" {
  description = "Name of the backend green target group"
  value       = aws_lb_target_group.backend_green.name
}
