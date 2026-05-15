provider "azurerm" {
  features {}
  use_oidc = true
}

provider "auth0" {
  domain        = data.azurerm_key_vault_secret.auth0_domain.value
  client_id     = data.azurerm_key_vault_secret.auth0_client_id.value
  client_secret = data.azurerm_key_vault_secret.auth0_client_secret.value
}
