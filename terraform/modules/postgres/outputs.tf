output "primary_fqdn" {
  value = azurerm_postgresql_flexible_server.primary.fqdn
}

output "replica_fqdn" {
  value = azurerm_postgresql_flexible_server.replica.fqdn
}

output "admin_login" {
  value = azurerm_postgresql_flexible_server.primary.administrator_login
}

output "database_name" {
  value = azurerm_postgresql_flexible_server_database.rag.name
}
