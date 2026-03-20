output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.main.name
}

output "pipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.main.arn
}

output "codestar_connection_arn" {
  description = "ARN of the CodeStar connection (requires manual console auth)"
  value       = aws_codestarconnections_connection.github.arn
}

output "artifact_bucket" {
  description = "Name of the pipeline artifact S3 bucket"
  value       = aws_s3_bucket.artifacts.bucket
}
