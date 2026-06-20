terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals {
  # Each workload: UAMI name, k8s namespace, k8s service-account name.
  workloads = {
    upload_api = {
      name      = "${var.name_prefix}-upload-api-${var.loc_short}"
      namespace = "ingestion"
      sa_name   = "upload-api"
    }
    embedding_worker = {
      name      = "${var.name_prefix}-embedding-worker-${var.loc_short}"
      namespace = "ingestion"
      sa_name   = "embedding-worker"
    }
    retrieval_api = {
      name      = "${var.name_prefix}-retrieval-api-${var.loc_short}"
      namespace = "query"
      sa_name   = "retrieval-api"
    }
    mcp_server = {
      name      = "${var.name_prefix}-mcp-server-${var.loc_short}"
      namespace = "query"
      sa_name   = "mcp-server"
    }
  }
}

resource "azurerm_user_assigned_identity" "this" {
  for_each            = local.workloads
  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "this" {
  for_each  = local.workloads
  name      = "${each.value.name}-fed"
  parent_id = azurerm_user_assigned_identity.this[each.key].id

  audience = ["api://AzureADTokenExchange"]
  issuer   = var.oidc_issuer_url
  subject  = "system:serviceaccount:${each.value.namespace}:${each.value.sa_name}"
}

# KEDA's azure-servicebus scaler authenticates as the keda-operator pod's
# workload identity. We federate the embedding-worker UAMI to the
# keda-operator ServiceAccount so KEDA can query queue depth with the same
# identity the worker uses, without provisioning a dedicated UAMI for KEDA.
resource "azurerm_federated_identity_credential" "keda_operator" {
  name      = "${local.workloads.embedding_worker.name}-keda-operator-fed"
  parent_id = azurerm_user_assigned_identity.this["embedding_worker"].id

  audience = ["api://AzureADTokenExchange"]
  issuer   = var.oidc_issuer_url
  subject  = "system:serviceaccount:keda:keda-operator"
}
