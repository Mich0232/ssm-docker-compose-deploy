locals {
  config_default_parameters = {
    "EnvFileName" = {
      type    = "String", description = "(Optional) The name of the configuration file to create.",
      default = "ssm-dc-deploy.env"
    }
    "WorkingDirectory" = {
      type        = "String",
      description = "(Optional) Path where the command should run. If empty, uses the SSM agent default.",
      default     = "/home/ec2-user"
    }
  }
  deploy_default_parameters = merge({
    "ComposeFilePath" = {
      type        = "String",
      description = "(Optional) The absolute path to the docker-compose.yml file on the instance.",
      default     = "docker-compose.yml"
    },
    "TargetInstanceId" = {
      type        = "String",
      description = "(Required) The ID of the EC2 instance to deploy to."
    }
  }, local.config_default_parameters)

  input_parameters = {
    for key, value in var.docker_compose_env_variables : key => {
      type        = "String"
      description = value.description
    }
  }
  step_parameters = {
    for key, value in var.docker_compose_env_variables : key => "{{ ${key} }}"
  }
  inline_env_variables = length(local.input_parameters) > 0 ? join("\n", [ for k in keys(local.input_parameters) : "${upper(k)}={{ ${k} }}"]) : "# No environment variables defined"
}


resource "aws_ssm_document" "config" {
  name            = "DockerComposeDeployEnvConfig"
  document_type   = "Command"
  document_format = "JSON"
  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Creates a file with environment variables for docker-compose.",
    parameters = merge(local.input_parameters, local.config_default_parameters),
    mainSteps = [
      {
        action = "aws:runShellScript",
        name   = "writeConfigurationFile",
        inputs = {
          workingDirectory = "{{ WorkingDirectory }}",
          runCommand = ["cat > \"{{ EnvFileName }}\" << EOF\n${local.inline_env_variables}\nEOF"]
        }
      }
    ]
  })
  tags = merge(local.common_tags, {
    Name = "DockerComposeDeployEnvConfig"
  })
}

resource "aws_ssm_document" "deploy" {
  name            = "DockerComposeDeploy"
  document_type   = "Automation"
  document_format = "JSON"

  depends_on = [aws_ssm_document.config]

  content = jsonencode({
    schemaVersion = "0.3"
    description   = "Automation Runbook: Deploys a docker-compose application and, on success, saves the tags using a separate command document.",
    assumeRole    = aws_iam_role.main.arn

    parameters = merge(local.input_parameters, local.deploy_default_parameters),
    mainSteps = [
      {
        name      = "setEnvironmentVariables",
        action    = "aws:runCommand",
        onFailure = "step:notifyDeploymentFailure",
        inputs = {
          DocumentName = aws_ssm_document.config.name,
          InstanceIds = ["{{ TargetInstanceId }}"],
          Parameters = merge(local.step_parameters, {
            EnvFileName = "{{ EnvFileName }}"
          })
        }
      },
      {
        name      = "deployApplication",
        action    = "aws:runCommand",
        onFailure = "step:notifyDeploymentFailure",
        inputs = {
          DocumentName = "AWS-RunShellScript",
          InstanceIds = ["{{ TargetInstanceId }}"],
          Parameters = {
            workingDirectory = "{{ WorkingDirectory }}",
            commands = [
              "docker-compose --env-file {{ EnvFileName }} -f {{ ComposeFilePath }} pull || exit 1;",
              "docker-compose --env-file {{ EnvFileName }} -f {{ ComposeFilePath }} up -d || exit 1;"
            ]
          }
        }
      },
      {
        name   = "notifyDeploymentSuccess",
        action = "aws:executeAwsApi",
        isEnd  = true,
        inputs = {
          Service  = "sns",
          Api      = "Publish",
          TopicArn = aws_sns_topic.main.arn,
          Subject  = var.sns_success_message_subject,
          Message  = var.sns_success_message_text
        }
      },
      {
        name   = "notifyDeploymentFailure",
        action = "aws:executeAwsApi",
        isEnd  = true,
        inputs = {
          Service  = "sns",
          Api      = "Publish",
          TopicArn = aws_sns_topic.main.arn,
          Subject  = var.sns_failure_message_subject,
          Message  = var.sns_failure_message_text
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "DockerComposeDeploy"
  })
}