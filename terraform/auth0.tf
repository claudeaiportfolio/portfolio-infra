module "auth0" {
  source = "./modules/auth0"

  auth0_apis    = var.auth0_apis
  auth0_clients = var.auth0_clients
}

output "api_identifiers" {
  description = "Auth0 API audience URLs"
  value       = module.auth0.api_identifiers
}

output "client_ids" {
  description = "Auth0 client IDs keyed by logical name"
  value       = module.auth0.client_ids
  sensitive   = true
}
