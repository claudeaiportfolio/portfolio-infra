# Changelog

All notable changes to the shared Terraform modules. Tags follow
`tf-modules-vX.Y.Z`. Consumers pin to a tag and re-pin on their own clock.

## tf-modules-v0.3.0 (unreleased)

Additive release: new **`aca`** module (Azure Container Apps). No changes to
existing modules — consumers on `tf-modules-v0.2.0` are unaffected and re-pin
only to adopt `aca`.

### Added

- **`aca`** — Azure **Container Apps** on a shared **Container App
  Environment**, fully parameterised (no solution/identifying literals). One
  module, **two workload kinds** via `workload_kind`:
  - `"app"` (default) — a long-running **Container App**: image + `cpu`/`memory`
    params, **scale-to-zero** (`min_replicas = 0`) with optional
    `custom_scale_rules` (KEDA), and ingress off by default / internal-only when
    enabled.
  - `"job"` — an on-demand **Container App Job** (`azurerm_container_app_job`)
    for episodic/batch **run-to-completion** work (container runs once + exits).
    Manual (on-demand) trigger via `manual_trigger_config` (`job_parallelism` /
    `job_replica_completion_count`) with `job_replica_timeout_in_seconds` /
    `job_replica_retry_limit`. Start an execution with `az containerapp job
    start`. (A scale-to-zero App with no ingress would deploy but never wake —
    the Job is the correct primitive for episodic work and lets an operator
    actually run + smoke-test it.)
  - Common to both: the shared **Environment** (VNet integration via
    `infrastructure_subnet_id` delegated to `Microsoft.App/environments`,
    `internal_ingress_only` internal LB, optional Log Analytics / zone
    redundancy / `workload_profiles`; precondition fails fast if
    internal/zone-redundant without a subnet); plain `env_vars` + Key
    Vault-backed `secret_env_vars`; and **all** secret / registry (ACR) auth via
    a caller-owned **user-assigned managed identity** (`user_assigned_identity_id`)
    — no admin users or stored passwords.
  - Does **not** declare `enable_private_endpoints`: Container Apps use VNet
    integration + an internal LB rather than a private endpoint, so the
    `anti-facade` rule does not apply (it governs only modules exposing that
    flag). The caller creates the UAMI and grants `AcrPull` + `Key Vault
    Secrets User`, keeping those identifying scopes out of the module body.
  - `examples/aca` (app + job, validate-only) + `tests/aca.tftest.hcl` (mocked
    provider, plan-only; app defaults, internal/private app, and job cases).
    Added to the policy-gate `validate` + `terraform-test` matrices.

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
