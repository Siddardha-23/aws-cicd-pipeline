variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB for CloudWatch metrics"
  type        = string
}

variable "frontend_tg_arn_suffix" {
  description = "ARN suffix of the frontend target group"
  type        = string
}

variable "backend_tg_arn_suffix" {
  description = "ARN suffix of the backend target group"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "frontend_service_name" {
  description = "Name of the frontend ECS service"
  type        = string
}

variable "backend_service_name" {
  description = "Name of the backend ECS service"
  type        = string
}

variable "alarm_email" {
  description = "Email address for alarm notifications"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
