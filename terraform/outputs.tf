output "alb_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "ecr_repo_urls" {
  description = "ECR repository URLs"
  value = {
    frontend   = module.ecr.frontend_repo_url
    core       = module.ecr.core_repo_url
    deployment = module.ecr.deployment_repo_url
  }
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_endpoint
}

output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = module.cicd.pipeline_name
}
