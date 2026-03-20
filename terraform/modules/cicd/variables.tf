variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to track"
  type        = string
  default     = "main"
}

variable "frontend_ecr_repo_uri" {
  description = "ECR repository URI for frontend"
  type        = string
}

variable "backend_ecr_repo_uri" {
  description = "ECR repository URI for backend"
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

variable "frontend_blue_tg_name" {
  description = "Name of the frontend blue target group"
  type        = string
}

variable "frontend_green_tg_name" {
  description = "Name of the frontend green target group"
  type        = string
}

variable "backend_blue_tg_name" {
  description = "Name of the backend blue target group"
  type        = string
}

variable "backend_green_tg_name" {
  description = "Name of the backend green target group"
  type        = string
}

variable "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  type        = string
}

variable "test_listener_arn" {
  description = "ARN of the test listener"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
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
