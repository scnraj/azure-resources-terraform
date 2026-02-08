variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-mygame-prod"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Australia East"
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = "asp-mygame-prod"
}

variable "app_service_name" {
  description = "Name of the App Service (must be globally unique)"
  type        = string
  default     = "app-mygame-prod"
}

variable "sku_name" {
  description = "SKU name for App Service Plan (B1, S1, P1V2, etc.)"
  type        = string
  default     = "B1" # Basic tier
}

variable "always_on" {
  description = "Should the app be loaded at all times"
  type        = bool
  default     = false # Only available in Basic tier and above
}

variable "custom_domain" {
  description = "Custom domain name"
  type        = string
  default     = "mygame.mahima.info"
}
