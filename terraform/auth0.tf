resource "auth0_resource_server" "apis" {
  for_each = var.auth0_apis

  name        = each.value.name
  identifier  = each.key
  signing_alg = "RS256"

  token_lifetime       = each.value.token_lifetime
  allow_offline_access = each.value.allow_offline

  skip_consent_for_verifiable_first_party_clients = false
}

resource "auth0_resource_server_scopes" "api_scopes" {
  for_each = var.auth0_apis

  resource_server_identifier = each.key

  dynamic "scopes" {
    for_each = each.value.scopes
    content {
      name        = scopes.key
      description = scopes.value
    }
  }

  depends_on = [auth0_resource_server.apis]
}

resource "auth0_client" "clients" {
  for_each = var.auth0_clients

  name     = each.value.name
  app_type = each.value.app_type

  callbacks           = each.value.callbacks
  allowed_logout_urls = each.value.logout_urls
  grant_types         = each.value.grant_types

  oidc_conformant = true

  jwt_configuration {
    alg = "RS256"
  }
}

resource "auth0_client_credentials" "clients" {
  for_each = var.auth0_clients

  client_id             = auth0_client.clients[each.key].id
  authentication_method = "none"
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
