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

resource "random_password" "admin" {
  length      = 32
  special     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
}

resource "azurerm_postgresql_flexible_server" "primary" {
  name                = "${var.name_prefix}-pg-${var.loc_short}"
  resource_group_name = var.resource_group_name
  location            = var.location

  version  = "16"
  sku_name = var.sku_name
  zone     = "1"

  administrator_login    = "pgadmin"
  administrator_password = random_password.admin.result

  storage_mb   = var.storage_mb
  storage_tier = "P10"

  authentication {
    password_auth_enabled         = true
    active_directory_auth_enabled = true
    tenant_id                     = var.tenant_id
  }

  public_network_access_enabled = !var.enable_private_endpoints

  backup_retention_days = 7

  tags = var.tags

  lifecycle {
    ignore_changes = [zone, high_availability[0].standby_availability_zone]
  }
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "this" {
  server_name         = azurerm_postgresql_flexible_server.primary.name
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  object_id           = var.aad_admin_object_id
  principal_name      = var.aad_admin_principal_name
  principal_type      = var.aad_admin_principal_type
}

# CI identity gets parallel admin so the postdeploy workflow can run
# CREATE EXTENSION + apply the rag schema without dragging the human into
# the loop. Both admins are independent — either can connect.
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "ci" {
  count = var.ci_admin_object_id == "" ? 0 : 1

  server_name         = azurerm_postgresql_flexible_server.primary.name
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  object_id           = var.ci_admin_object_id
  principal_name      = var.ci_admin_principal_name
  principal_type      = "ServicePrincipal"
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "workload" {
  for_each = var.workload_admins

  server_name         = azurerm_postgresql_flexible_server.primary.name
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  object_id           = each.value.object_id
  principal_name      = each.value.principal_name
  principal_type      = "ServicePrincipal"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.primary.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# AKS pods reach Postgres via the public hostname too — Microsoft Azure
# egress IPs are not predictable per region without VNet integration, so
# AllowAzureServices is required for both the GitHub runner and the
# cluster. Tightened to a private endpoint by flipping
# var.enable_private_endpoints (handoff stage 9).

resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.primary.id
  value     = "VECTOR"
}

resource "azurerm_postgresql_flexible_server_database" "rag" {
  name      = "rag"
  server_id = azurerm_postgresql_flexible_server.primary.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server" "replica" {
  name                = "${var.name_prefix}-pg-replica-${var.loc_short}"
  resource_group_name = var.resource_group_name
  location            = var.location

  create_mode      = "Replica"
  source_server_id = azurerm_postgresql_flexible_server.primary.id

  public_network_access_enabled = !var.enable_private_endpoints

  tags = var.tags

  lifecycle {
    ignore_changes = [zone, high_availability[0].standby_availability_zone]
  }
}

# Replica needs the same auth + firewall posture as primary — retrieval-api
# pods connect to it via PG_REPLICA_HOST using their workload-identity token.
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_replica" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.replica.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}


# Microsoft Entra admins replicate automatically from primary to replica —
# do not create them as separate TF resources or apply will fail with
# "already exists". Firewall rules do NOT replicate, which is why the
# replica firewall above is still explicit.
