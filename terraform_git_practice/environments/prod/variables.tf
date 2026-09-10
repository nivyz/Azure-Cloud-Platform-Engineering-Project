variable "subscription_id" {
  description = "Azure subscription ID used for deployment."
  type        = string
}

variable "project_name" {
  description = "Short project name used in resource names."
  type        = string
  default     = "tfpractice"
}

variable "location" {
  description = "Azure deployment region."
  type        = string
  default     = "westeurope"
}

variable "tags" {
  description = "Additional tags applied to resources."
  type        = map(string)
  default     = {}
}
