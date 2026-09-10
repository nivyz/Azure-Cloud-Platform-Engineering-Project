output "resource_group_id" {
  description = "ID of the QA resource group."
  value       = module.resource_group.id
}

output "resource_group_name" {
  description = "Name of the QA resource group."
  value       = module.resource_group.name
}
