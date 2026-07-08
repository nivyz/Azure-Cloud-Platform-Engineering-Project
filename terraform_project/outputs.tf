output "public_ip_address" {
  description = "Public IP address assigned to the Linux VM."
  value       = azurerm_public_ip.vm.ip_address
}

output "ssh_command" {
  description = "Example SSH command for connecting to the Linux VM after Terraform apply completes."
  value       = "ssh -i ${trimsuffix(var.ssh_public_key_path, ".pub")} ${var.admin_username}@${azurerm_public_ip.vm.ip_address}"
}

output "web_url" {
  description = "HTTP URL for the Nginx page installed by cloud-init on the public VM."
  value       = "http://${azurerm_public_ip.vm.ip_address}"
}

output "private_vm_private_ip_address" {
  description = "Private IP address assigned to the second VM."
  value       = azurerm_network_interface.private_vm.private_ip_address
}

output "private_vm_ssh_via_jump_command" {
  description = "SSH command for connecting to the private VM through the public VM without copying private keys."
  value       = "ssh -i ${trimsuffix(var.ssh_public_key_path, ".pub")} -J ${var.admin_username}@${azurerm_public_ip.vm.ip_address} ${var.admin_username}@${azurerm_network_interface.private_vm.private_ip_address}"
}
