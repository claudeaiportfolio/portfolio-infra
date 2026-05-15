output "api_identifiers" {
  description = "Auth0 API audience URLs"
  value       = keys(auth0_resource_server.apis)
}

output "client_ids" {
  description = "Auth0 client IDs keyed by logical name"
  value       = { for k, v in auth0_client.clients : k => v.client_id }
  sensitive   = true
}
