variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region for ECR login"
  type        = string
}

variable "source_path" {
  description = "Absolute path to the project root containing Dockerfiles"
  type        = string
}
