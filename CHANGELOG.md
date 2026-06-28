# Changelog

All notable changes to the shared Terraform modules. Tags follow
`tf-modules-vX.Y.Z`. Consumers pin to a tag and re-pin on their own clock.

## tf-modules-v0.2.0 (unreleased)

Interface release: removed all solution-coupled literals from module bodies,
replaced the private-networking facade flags with real private endpoints, and
stood up an IaC policy gate. **Breaking** for consumers — see the interface
changes below. Consumers re-pin deliberately; the previously published
`tf-modules-v0.1.0` is unchanged.

### Breaking interface changes

**postgres**
- Added **required** `database_name` (was hardcoded `"rag"`).
- Added `server_extensions` `list(string)` default `[]` (was hardcoded
  `azure.extensions = "VECTOR"`; no config created when empty).
- Added `database_charset` / `database_collation` (defaults `UTF8` /
  `en_US.utf8`).
- Added real private endpoints: `private_endpoint_subnet_id`,
  `private_dns_zone_id`. `enable_private_endpoints = true` now creates
  `azurerm_private_endpoint` resources (primary + replica) with DNS wiring,
  not just a public-access flip.
- New outputs: `primary_private_endpoint_id`, `replica_private_endpoint_id`.
- Internal: database resource renamed `azurerm_postgresql_flexible_server_database.rag`
  → `.this` (state-move needed on upgrade — see below).

**identity**
- Replaced the four hardcoded workloads (upload_api / embedding_worker /
  retrieval_api / mcp_server) and the fixed namespaces/service-accounts with a
  single `workloads` `map(object({...}))` var, default `{}`, iterated with
  `for_each`.
- Added `extra_federated_subjects` per workload — generalises the old
  KEDA-operator federation special case.
- **Removed** the fixed outputs `upload_api` / `embedding_worker` /
  `retrieval_api` / `mcp_server`. Replaced by a single `workloads` map output;
  index it by your own keys.

**storage**
- Replaced the fixed `documents` container with a `containers` `set(string)`,
  default `[]`.
- Replaced the two fixed principal vars (`upload_api_principal_id`,
  `worker_principal_id`) with a `role_assignments` `map(object({principal_id,
  role_definition_name}))`, default `{}`.
- Replaced the fixed `documents/processed/` lifecycle rule with a
  `lifecycle_rules` list var, default `[]` (no management policy when empty).
- Added real blob private endpoint: `private_endpoint_subnet_id`,
  `private_dns_zone_id`; `enable_private_endpoints = true` creates a real
  `azurerm_private_endpoint`.
- **Removed** output `container_name`; added `container_names` (map) and
  `blob_private_endpoint_id`.

**openai**
- Replaced the two fixed principal vars (`worker_principal_id`,
  `retrieval_principal_id`) with an `openai_user_principal_ids` `set(string)`,
  default `[]`.
- Added real account private endpoint: `private_endpoint_subnet_id`,
  `private_dns_zone_id`; `enable_private_endpoints = true` creates a real
  `azurerm_private_endpoint`.
- New output `private_endpoint_id`.

### Added

- **Shared networking** (root `terraform/network.tf`): dedicated VNet, a subnet
  delegated to `Microsoft.App/environments` (ACA), a private-endpoint subnet,
  and `privatelink.postgres.database.azure.com` / `...blob.core.windows.net` /
  `...openai.azure.com` private DNS zones with VNet links. Outputs: `shared_vnet_id`,
  `aca_subnet_id`, `private_endpoint_subnet_id`, `private_dns_zone_ids`.
- **Terraform policy gate** (`.github/workflows/terraform-policy.yml`, runs on
  PR + push): `fmt -check`, per-dir `validate`, custom policy
  (`policy/policy_check.py`: `no-identifying-literals` + `anti-facade`, BLOCKING),
  `terraform test`, and advisory `checkov`.
- **`examples/`** (validate-only) for postgres / identity / storage / openai with
  neutral values.
- **`tests/*.tftest.hcl`** for postgres / identity / storage / openai (mocked
  providers, plan-only).
- **`docs/production-readiness-checklist.md`**.

### Upgrade notes (state moves)

The postgres database resource was renamed. On upgrade, move state to avoid a
destroy/recreate of the database:

```
terraform state mv \
  'module.postgres.azurerm_postgresql_flexible_server_database.rag' \
  'module.postgres.azurerm_postgresql_flexible_server_database.this'
```

Identity/storage consumers that switch to the new map/set vars should expect
`for_each` key changes; review the plan before applying.

### Deferred human apply steps

CI never runs `terraform apply`. After merge + tag, a human applies:

1. The shared network (`terraform/network.tf`) — SHARED infra.
2. Per consuming solution: re-pin to `tf-modules-v0.2.0`, set
   `enable_private_endpoints = true` and wire `private_endpoint_subnet_id` /
   `private_dns_zone_id` from the shared network outputs, then `apply`.

## tf-modules-v0.1.0

Initial shared modules: auth0, identity, storage, postgres, openai, aks-nodepool.
