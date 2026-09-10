variable "subscription_id" {
  description = "Azure subscription ID used for deployment."
  type        = string
}

variable "project_name" {
  description = "Short lowercase project name used in Azure resource names."
  type        = string
  default     = "tfpractice"

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.project_name))
    error_message = "project_name must contain 3-12 lowercase letters or digits."
  }
}

variable "location" {
  description = "Azure region used for the state resources."
  type        = string
  default     = "westeurope"
}

variable "tags" {
  description = "Tags applied to the state resources."
  type        = map(string)
  default = {
    managed_by = "terraform"
    purpose    = "terraform-state"
  }
}
