terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_string" "subdomain_suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_cognitive_account" "this" {
  name                = "${var.name_prefix}-aoai-${var.loc_short}"
  resource_group_name = var.resource_group_name
  location            = var.location

  kind     = "OpenAI"
  sku_name = "S0"

  custom_subdomain_name         = "${var.name_prefix}-aoai-${var.loc_short}-${random_string.subdomain_suffix.result}"
  local_auth_enabled            = false
  public_network_access_enabled = !var.enable_private_endpoints

  tags = var.tags
}

resource "azurerm_cognitive_deployment" "embedding" {
  name                 = "embedding"
  cognitive_account_id = azurerm_cognitive_account.this.id

  model {
    format  = "OpenAI"
    name    = "text-embedding-3-small"
    version = "1"
  }

  sku {
    name     = "GlobalStandard"
    capacity = var.embedding_capacity
  }
}

resource "azurerm_cognitive_deployment" "chat" {
  name                 = "chat"
  cognitive_account_id = azurerm_cognitive_account.this.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o-mini"
    version = "2024-07-18"
  }

  sku {
    name     = "GlobalStandard"
    capacity = var.chat_capacity
  }
}

resource "azurerm_role_assignment" "worker_aoai_user" {
  scope                = azurerm_cognitive_account.this.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = var.worker_principal_id
}

resource "azurerm_role_assignment" "retrieval_aoai_user" {
  scope                = azurerm_cognitive_account.this.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = var.retrieval_principal_id
}
