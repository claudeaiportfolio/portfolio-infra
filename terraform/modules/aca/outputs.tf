output "environment_id" {
  description = "ID of the Container App Environment."
  value       = azurerm_container_app_environment.this.id
}

output "environment_default_domain" {
  description = "Default domain of the Container App Environment (suffix for app FQDNs)."
  value       = azurerm_container_app_environment.this.default_domain
}

output "environment_static_ip_address" {
  description = "Static IP of the environment's load balancer (internal IP when internal_ingress_only)."
  value       = azurerm_container_app_environment.this.static_ip_address
}

output "container_app_id" {
  description = "ID of the Container App."
  value       = azurerm_container_app.this.id
}

output "container_app_name" {
  description = "Name of the Container App."
  value       = azurerm_container_app.this.name
}

output "latest_revision_fqdn" {
  description = "FQDN of the latest revision (null when ingress is disabled)."
  value       = azurerm_container_app.this.latest_revision_fqdn
}
