module "auth0" {
  source = "./modules/auth0"

  auth0_apis    = var.auth0_apis
  auth0_clients = var.auth0_clients
  key_vault_id  = data.azurerm_key_vault.main.id
}
