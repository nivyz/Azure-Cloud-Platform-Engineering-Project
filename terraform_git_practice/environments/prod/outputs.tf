output "resource_group_id" {
  description = "ID of the production resource group."
  value       = module.resource_group.id
}

output "resource_group_name" {
  description = "Name of the production resource group."
  value       = module.resource_group.name
}
