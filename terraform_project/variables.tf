variable "subscription_id" {
  description = "Azure subscription ID where Terraform will create the VM resources."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "The subscription_id value must look like a valid Azure subscription UUID."
  }
}

variable "location" {
  description = "Azure region for all resources, for example eastasia, eastus, westeurope, or germanywestcentral."
  type        = string
  default     = "eastasia"
}

variable "resource_group_name" {
  description = "Name of the resource group Terraform will create."
  type        = string
  default     = "rg-beginner-linux-vm"
}

variable "vm_size" {
  description = "Azure VM size to deploy."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "private_vm_size" {
  description = "Azure VM size for the private worker VM."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Linux administrator username for SSH login."
  type        = string
  default     = "azureuser"

  validation {
    condition     = !contains(["admin", "administrator", "root"], lower(var.admin_username))
    error_message = "Use a non-reserved Linux username, such as azureuser."
  }
}

variable "ssh_public_key_path" {
  description = "Local path to your RSA SSH public key file. Azure Linux VMs require an RSA public key."
  type        = string
  default     = "~/.ssh/id_rsa_azure_vm.pub"
}

variable "my_public_ip_cidr" {
  description = "Your public IP address in CIDR format, for example 203.0.113.10/32. SSH will only be allowed from this CIDR."
  type        = string

  validation {
    condition     = can(cidrhost(var.my_public_ip_cidr, 0)) && var.my_public_ip_cidr != "0.0.0.0/0"
    error_message = "Enter a valid CIDR block and do not use 0.0.0.0/0."
  }
}

variable "auto_shutdown_time" {
  description = "Daily VM auto-shutdown time in 24-hour HHMM format."
  type        = string
  default     = "1900"

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3])[0-5][0-9]$", var.auto_shutdown_time))
    error_message = "Use HHMM 24-hour format, for example 1900."
  }
}

variable "auto_shutdown_timezone" {
  description = "Timezone used by the Azure auto-shutdown schedule."
  type        = string
  default     = "UTC"
}

variable "tags" {
  description = "Common tags applied to taggable Azure resources."
  type        = map(string)
  default = {
    project     = "terraform-azure-vm-lab"
    environment = "lab"
    owner       = "samun"
    ttl         = "destroy-after-lab"
  }
}
