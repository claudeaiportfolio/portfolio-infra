output "endpoint" {
  value = azurerm_cognitive_account.this.endpoint
}

output "account_name" {
  value = azurerm_cognitive_account.this.name
}

output "embedding_deployment" {
  value = azurerm_cognitive_deployment.embedding.name
}

output "chat_deployment" {
  value = azurerm_cognitive_deployment.chat.name
}
