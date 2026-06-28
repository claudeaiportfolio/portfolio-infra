# Shared networking outputs (B2). Consuming solutions / modules wire their
# private endpoints to these subnet + DNS-zone IDs.

output "shared_vnet_id" {
  description = "ID of the shared VNet."
  value       = azurerm_virtual_network.shared.id
}

output "aca_subnet_id" {
  description = "ID of the subnet delegated to Microsoft.App/environments (Azure Container Apps)."
  value       = azurerm_subnet.aca.id
}

output "private_endpoint_subnet_id" {
  description = "ID of the subnet hosting private endpoint NICs."
  value       = azurerm_subnet.private_endpoints.id
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone IDs keyed by service (postgres/blob/openai)."
  value       = { for k, z in azurerm_private_dns_zone.this : k => z.id }
}
