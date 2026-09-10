locals {
  environment = "qa"
  common_tags = merge(var.tags, {
    environment = local.environment
    managed_by  = "terraform"
    project     = var.project_name
  })
}

module "resource_group" {
  source = "../../modules/resource-group"

  name     = "rg-${var.project_name}-${local.environment}"
  location = var.location
  tags     = local.common_tags
}
