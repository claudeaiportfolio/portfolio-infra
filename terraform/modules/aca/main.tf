terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals {
  environment_name = var.environment_name != "" ? var.environment_name : "${var.name_prefix}-aca-env-${var.loc_short}"
  app_name         = var.app_name != "" ? var.app_name : "${var.name_prefix}-app-${var.loc_short}"
  container_name   = var.container_name != "" ? var.container_name : "${var.name_prefix}-app"

  # Merge plain env vars and secret-backed env vars into one list the container
  # `env` block iterates. A single source of truth so a new var is added in one
  # place, never hand-synced across two blocks.
  container_env = concat(
    [for k, v in var.env_vars : { name = k, value = v, secret_name = null }],
    [for k, s in var.secret_env_vars : { name = k, value = null, secret_name = s }],
  )
}

# --- Container App Environment --------------------------------------------
# VNet-integrated when infrastructure_subnet_id is set; INTERNAL load balancer
# (no public ingress) when internal_ingress_only is true. Workload profiles are
# opt-in — an empty list is a Consumption-only environment, which still supports
# both VNet integration and scale-to-zero.
resource "azurerm_container_app_environment" "this" {
  name                = local.environment_name
  resource_group_name = var.resource_group_name
  location            = var.location

  infrastructure_subnet_id   = var.infrastructure_subnet_id != "" ? var.infrastructure_subnet_id : null
  log_analytics_workspace_id = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : null

  # The provider requires these to be set ONLY alongside infrastructure_subnet_id;
  # leave them unset (null) for a non-VNet environment. The precondition below
  # guarantees they are false when there is no subnet, so null loses nothing.
  internal_load_balancer_enabled = var.infrastructure_subnet_id != "" ? var.internal_ingress_only : null
  zone_redundancy_enabled        = var.infrastructure_subnet_id != "" ? var.zone_redundancy_enabled : null

  dynamic "workload_profile" {
    for_each = var.workload_profiles
    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.type
      minimum_count         = workload_profile.value.minimum_count
      maximum_count         = workload_profile.value.maximum_count
    }
  }

  tags = var.tags

  # An internal load balancer or zone redundancy requires a delegated subnet to
  # land the environment in — fail fast rather than at apply.
  lifecycle {
    precondition {
      condition     = !(var.internal_ingress_only || var.zone_redundancy_enabled) || var.infrastructure_subnet_id != ""
      error_message = "internal_ingress_only / zone_redundancy_enabled require infrastructure_subnet_id to be set."
    }
  }
}

# --- Container App ---------------------------------------------------------
resource "azurerm_container_app" "this" {
  name                         = local.app_name
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  workload_profile_name        = var.workload_profile_name != "" ? var.workload_profile_name : null

  # User-assigned identity used for KV secret refs + ACR pull. No system
  # identity — the caller owns the UAMI and its role grants.
  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  # ACR auth via the user-assigned identity (no admin user / stored password).
  dynamic "registry" {
    for_each = var.registry_server != "" ? [var.registry_server] : []
    content {
      server   = registry.value
      identity = var.user_assigned_identity_id
    }
  }

  # Key Vault-backed secrets, resolved at runtime through the UAMI.
  dynamic "secret" {
    for_each = { for s in var.secrets : s.name => s }
    content {
      name                = secret.value.name
      key_vault_secret_id = secret.value.key_vault_secret_id
      identity            = var.user_assigned_identity_id
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = local.container_name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = { for e in local.container_env : e.name => e }
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }
    }

    dynamic "custom_scale_rule" {
      for_each = { for r in var.custom_scale_rules : r.name => r }
      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.custom_rule_type
        metadata         = custom_scale_rule.value.metadata
      }
    }
  }

  dynamic "ingress" {
    for_each = var.ingress_enabled ? [1] : []
    content {
      external_enabled = var.ingress_external_enabled
      target_port      = var.ingress_target_port
      transport        = "auto"

      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }

  tags = var.tags
}
