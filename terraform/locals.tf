locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    CostCenter  = "${var.project_name}-cicd"
    ManagedBy   = "terraform"
  }
}
