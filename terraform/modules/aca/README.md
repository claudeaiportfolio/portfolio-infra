# aca module

Azure **Container App** + **Container App Environment**, shaped for the
portfolio: VNet-integrated, optionally internal-only (no public ingress),
scale-to-zero, with secrets sourced from Key Vault and registry auth via a
**user-assigned managed identity** the caller owns.

Like every module here the body carries **no** solution-specific or identifying
literals — image, registry, secrets, subnet/DNS/identity IDs are all inputs.

## What it creates

| Resource | Notes |
|----------|-------|
| `azurerm_container_app_environment.this` | VNet-integrated when `infrastructure_subnet_id` set; internal LB when `internal_ingress_only`; Consumption-only unless `workload_profiles` given; optional Log Analytics + zone redundancy. |
| `azurerm_container_app.this` | Single-revision app; `UserAssigned` identity; optional ACR `registry` (MI auth); KV-backed `secret` blocks (MI auth); `template` with scale-to-zero (`min_replicas` default 0) + optional `custom_scale_rule`s; optional internal/external `ingress`. |

## Identity, secrets & registry (managed-identity, no stored creds)

The module does **not** create the managed identity or its role assignments —
the caller creates a UAMI and grants it `AcrPull` on the registry and
`Key Vault Secrets User` on the vault, then passes `user_assigned_identity_id`.
That keeps registry/KV scopes (identifying resource IDs) out of the shared
module body. The app then:

- authenticates to ACR with the UAMI (`registry.identity`),
- resolves each `secrets[*].key_vault_secret_id` through the UAMI at runtime,
- exposes them as env vars via `secret_env_vars` (`ENV_NAME => secret name`).

## Private networking

This module uses **VNet integration** (`infrastructure_subnet_id`, delegated to
`Microsoft.App/environments`) plus an **internal load balancer**
(`internal_ingress_only = true`) for the no-public-ingress posture — Container
Apps are fronted this way rather than by a private endpoint. It therefore does
**not** declare an `enable_private_endpoints` flag, so the repo's `anti-facade`
policy rule does not apply here (that rule only governs modules that expose the
flag). Datastores in the same solution (postgres/storage) supply the real
private endpoints.

## Consume

```hcl
module "aca" {
  source = "git::https://github.com/claudeaiportfolio/portfolio-infra.git//terraform/modules/aca?ref=tf-modules-vX.Y.Z"

  resource_group_name = azurerm_resource_group.app.name
  location            = "uksouth"
  name_prefix         = "myapp"
  loc_short           = "uks"

  # VNet-integrated, no public ingress, scale-to-zero.
  infrastructure_subnet_id = data.terraform_remote_state.shared.outputs.aca_subnet_id
  internal_ingress_only    = true
  min_replicas             = 0
  max_replicas             = 1

  image                     = var.image            # <acr>.azurecr.io/<repo>:<tag>
  registry_server           = var.registry_server  # <acr>.azurecr.io
  user_assigned_identity_id = azurerm_user_assigned_identity.app.id

  secrets = [
    { name = "anthropic-api-key", key_vault_secret_id = azurerm_key_vault_secret.anthropic.versionless_id },
  ]
  secret_env_vars = { ANTHROPIC_API_KEY = "anthropic-api-key" }
  env_vars        = { SEC_EDGAR_USER_AGENT = var.edgar_user_agent }
}
```

Grant the UAMI its roles in the caller (`AcrPull` + `Key Vault Secrets User`)
and add `depends_on = [<the KV role assignment>]` to the module block so the
first revision can read the secrets on create.

## Scale-to-zero note

`min_replicas = 0` with **no ingress** means nothing wakes the app on its own —
add an event source under `custom_scale_rules` (cron / azure-queue /
azure-servicebus) to schedule or event-trigger runs in production. Left empty,
the app is deployable and reachable only by an explicit revision restart.
