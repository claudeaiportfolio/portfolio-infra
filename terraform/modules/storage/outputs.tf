output "account_name" {
  value = azurerm_storage_account.this.name
}

output "account_id" {
  value = azurerm_storage_account.this.id
}

output "container_name" {
  value = azurerm_storage_container.documents.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}
