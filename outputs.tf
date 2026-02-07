output "app_service_default_hostname" {
  description = "Default hostname of the App Service"
  value       = azurerm_linux_web_app.main.default_hostname
}

output "app_service_id" {
  description = "ID of the App Service"
  value       = azurerm_linux_web_app.main.id
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.main.name
}

output "custom_domain" {
  description = "Custom domain configured"
  value       = var.custom_domain
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "certificate_thumbprint" {
  description = "Thumbprint of the managed certificate"
  value       = azurerm_app_service_managed_certificate.main.thumbprint
  sensitive   = true
}
