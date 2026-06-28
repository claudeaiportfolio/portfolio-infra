# Shared private networking for the portfolio (B2).
#
# This is SHARED infrastructure: one VNet with (a) a subnet delegated to
# Microsoft.App/environments for Azure Container Apps, (b) a subnet for private
# endpoint NICs, and (c) the private DNS zones that resolve the privatelink
# FQDNs to those endpoints. The postgres/storage/openai modules consume the
# subnet + DNS-zone IDs output here to stand up REAL private endpoints.
#
# NOTE: applying these resources is a DEFERRED human step (see CHANGELOG /
# PR body). Authored here so the wiring is reviewable; not applied by CI.

resource "azurerm_resource_group" "shared_network" {
  name     = var.shared_network_resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "shared" {
  name                = "${var.name_prefix}-vnet-${var.loc_short}"
  resource_group_name = azurerm_resource_group.shared_network.name
  location            = azurerm_resource_group.shared_network.location
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Subnet delegated to Azure Container Apps managed environments.
resource "azurerm_subnet" "aca" {
  name                 = "aca-environment"
  resource_group_name  = azurerm_resource_group.shared_network.name
  virtual_network_name = azurerm_virtual_network.shared.name
  address_prefixes     = var.aca_subnet_prefixes

  delegation {
    name = "aca-delegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Subnet hosting private endpoint NICs.
resource "azurerm_subnet" "private_endpoints" {
  name                 = "private-endpoints"
  resource_group_name  = azurerm_resource_group.shared_network.name
  virtual_network_name = azurerm_virtual_network.shared.name
  address_prefixes     = var.private_endpoint_subnet_prefixes
}

# --- Private DNS zones + VNet links ---------------------------------------
locals {
  private_dns_zones = {
    postgres = "privatelink.postgres.database.azure.com"
    blob     = "privatelink.blob.core.windows.net"
    openai   = "privatelink.openai.azure.com"
  }
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.shared_network.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each              = local.private_dns_zones
  name                  = "${each.key}-link"
  resource_group_name   = azurerm_resource_group.shared_network.name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = azurerm_virtual_network.shared.id
  registration_enabled  = false
  tags                  = var.tags
}
