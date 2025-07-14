variable "resource_prefix" {
  type        = string
  description = "Terraform resource prefix. Setting this to 'app-staging' will create resources named 'app-staging-iam-role'"
  default     = ""

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]*$", var.resource_prefix))
    error_message = "Resource prefix must contain only alphanumeric characters and hyphens."
  }
}

variable "tags" {
  type        = map(string)
  description = "Map of default tags to include in every resource created"
  default     = {}
}

variable "default_iam_policy_name" {
  type        = string
  description = "Name of AWS managed policy to attach."
  default     = "AmazonSSMAutomationRole"
}

variable "docker_compose_env_variables" {
  type = map(object({
    description = string
    default     = optional(string)
  }))
  description = "Environment variables to pass to docker-compose"
  default     = {}
}

variable "sns_success_message_subject" {
  type        = string
  description = "AWS SNS success notification message subject"
  default     = "🚀 Deployment Success"

  validation {
    condition     = length(var.sns_success_message_subject) <= 100
    error_message = "SNS subject must be 100 characters or less."
  }
}

variable "sns_success_message_text" {
  type        = string
  description = "AWS SNS success notification message text"
  default     = "Docker Compose deployment completed successfully!\n\nDeployment Details:\n- Target Instance: {{ TargetInstanceId }}\n- Compose File: {{ ComposeFilePath }}\n- Working Directory: {{ WorkingDirectory }}\n\nTimestamp: {{ automation:EXECUTION_ID }}"
}

variable "sns_failure_message_subject" {
  type        = string
  description = "AWS SNS failure notification message subject"
  default     = "❌ Deployment Failure"

  validation {
    condition     = length(var.sns_failure_message_subject) <= 100
    error_message = "SNS subject must be 100 characters or less."
  }
}

variable "sns_failure_message_text" {
  type        = string
  description = "AWS SNS failure notification message text"
  default     = "Docker Compose deployment failed!\n\nDeployment Details:\n- Target Instance: {{ TargetInstanceId }}\n- Compose File: {{ ComposeFilePath }}\n- Working Directory: {{ WorkingDirectory }}\n\nPlease check the SSM execution logs for more details.\nExecution ID: {{ automation:EXECUTION_ID }}"
}