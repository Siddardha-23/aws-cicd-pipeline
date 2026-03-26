variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "db_host" {
  description = "Database host endpoint"
  type        = string
}

variable "core_db_name" {
  description = "Database name for core-service"
  type        = string
  default     = "opsboard_core"
}

variable "deployment_db_name" {
  description = "Database name for deployment-service"
  type        = string
  default     = "opsboard_deployments"
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Database port"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
