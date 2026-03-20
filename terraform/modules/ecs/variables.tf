variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "frontend_sg_id" {
  description = "Security group ID for frontend tasks"
  type        = string
}

variable "backend_sg_id" {
  description = "Security group ID for backend tasks"
  type        = string
}

variable "frontend_repo_url" {
  description = "ECR repository URL for frontend"
  type        = string
}

variable "backend_repo_url" {
  description = "ECR repository URL for backend"
  type        = string
}

variable "frontend_tg_arn" {
  description = "ARN of the frontend blue target group"
  type        = string
}

variable "backend_tg_arn" {
  description = "ARN of the backend blue target group"
  type        = string
}

variable "ssm_parameter_arns" {
  description = "List of SSM parameter ARNs the task execution role needs access to"
  type        = list(string)
}

variable "ssm_parameter_names" {
  description = "Map of SSM parameter names"
  type        = map(string)
}

variable "container_insights" {
  description = "Enable ECS container insights"
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
