output "sns_topic_arn" {
  description = "ARN of the SNS alarm topic"
  value       = aws_sns_topic.alarms.arn
}
