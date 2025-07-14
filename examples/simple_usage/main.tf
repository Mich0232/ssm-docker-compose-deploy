terraform {
  required_version = ">= 1.5.7"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "docker_compose_deploy" {
  source = "../../"

  resource_prefix = "app-staging"

  docker_compose_env_variables = {
    VERSION = {
      description = "Version of the application to deploy"
      default     = "latest"
    }
    PORT = {
      description = "Port to expose the application on"
      default     = "80"
    }
  }

  sns_success_message_subject = "Good news!"
  sns_failure_message_subject = "About that deploy..."

  tags = {
    Owner = "DevOps"
  }
} 