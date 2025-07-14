output "ssm_document_config_name" {
  description = "Name of the SSM document for environment configuration"
  value       = aws_ssm_document.config.name
}

output "ssm_document_deploy_name" {
  description = "Name of the SSM document for deployment automation"
  value       = aws_ssm_document.deploy.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for deployment notifications"
  value       = aws_sns_topic.main.arn
}

output "iam_role_arn" {
  description = "ARN of the IAM role used by SSM automation"
  value       = aws_iam_role.main.arn
}

output "iam_role_name" {
  description = "Name of the IAM role used by SSM automation"
  value       = aws_iam_role.main.name
}
