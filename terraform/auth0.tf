resource "auth0_resource_server" "apis" {
  for_each = var.auth0_apis

  name        = each.value.name
  identifier  = each.key
  signing_alg = "RS256"

  token_lifetime       = each.value.token_lifetime
  allow_offline_access = each.value.allow_offline

  skip_consent_for_verifiable_first_party_clients = false

  dynamic "scopes" {
    for_each = each.value.scopes
    content {
      value       = scopes.key
      description = scopes.value
    }
  }
}

resource "auth0_client" "clients" {
  for_each = var.auth0_clients

  name     = each.value.name
  app_type = each.value.app_type

  callbacks           = each.value.callbacks
  allowed_logout_urls = each.value.logout_urls
  grant_types         = each.value.grant_types

  token_endpoint_auth_method = "none"
  oidc_conformant            = true

  jwt_configuration {
    alg = "RS256"
  }
}

output "api_identifiers" {
  description = "Auth0 API audience URLs"
  value       = keys(auth0_resource_server.apis)
}

output "client_ids" {
  description = "Auth0 client IDs keyed by logical name"
  value       = { for k, v in auth0_client.clients : k => v.client_id }
  sensitive   = true
}
