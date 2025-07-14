locals {
  name = var.resource_prefix != "" ? "${var.resource_prefix}-ssm-dc-deployments" : "ssm-dc-deployments"
  common_tags = merge(var.tags, {
    TFWorkspace = terraform.workspace
    ManagedBy   = "Terraform"
  })
}
