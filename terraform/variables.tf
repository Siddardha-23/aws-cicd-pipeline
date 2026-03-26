variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "opsboard"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "cicd.manneharshithsiddardha.com"
}

variable "root_domain" {
  description = "Root domain for the hosted zone"
  type        = string
  default     = "manneharshithsiddardha.com"
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_insights" {
  description = "Enable ECS container insights (adds cost)"
  type        = bool
  default     = false
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = ""
}
