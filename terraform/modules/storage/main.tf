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

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "this" {
  name                = "${var.name_prefix}st${var.loc_short}${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  shared_access_key_enabled       = false
  public_network_access_enabled   = !var.enable_private_endpoints
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  default_to_oauth_authentication = true

  blob_properties {
    last_access_time_enabled = true
    versioning_enabled       = false
    change_feed_enabled      = false
  }

  tags = var.tags
}

resource "azurerm_storage_container" "documents" {
  name                  = "documents"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "this" {
  storage_account_id = azurerm_storage_account.this.id

  rule {
    name    = "tier-processed-cool"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["documents/processed/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
      }
    }
  }
}

resource "azurerm_role_assignment" "upload_api_blob_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.upload_api_principal_id
}

resource "azurerm_role_assignment" "worker_blob_reader" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.worker_principal_id
}
