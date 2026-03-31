output "frontend_repo_url" {
  description = "URL of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.repository_url
}

output "core_repo_url" {
  description = "URL of the core service ECR repository"
  value       = aws_ecr_repository.core.repository_url
}

output "deployment_repo_url" {
  description = "URL of the deployment service ECR repository"
  value       = aws_ecr_repository.deployment.repository_url
}

output "frontend_repo_arn" {
  description = "ARN of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.arn
}

output "core_repo_arn" {
  description = "ARN of the core service ECR repository"
  value       = aws_ecr_repository.core.arn
}

output "deployment_repo_arn" {
  description = "ARN of the deployment service ECR repository"
  value       = aws_ecr_repository.deployment.arn
}

output "images_pushed" {
  description = "Signals that initial images have been pushed to ECR"
  value       = null_resource.initial_image_push.id
}
