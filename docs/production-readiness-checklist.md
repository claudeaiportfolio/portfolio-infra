# Module production-readiness checklist

Every shared module in `terraform/modules/` is meant to be lift-and-drop
reference code. This checklist is the bar each module is held to, and what the
CI policy gate (`.github/workflows/terraform-policy.yml`) enforces mechanically.

## Cross-cutting (all modules)

- [x] **No identifying literals in module bodies** — solution names, container
      names, workload names, namespaces are caller-supplied variables, never
      hardcoded. Enforced by the `no-identifying-literals` rule in
      `policy/policy_check.py`.
- [x] **Neutral or required defaults** — variables default to neutral/empty
      values or are required; never to a specific solution's values.
- [x] **No facade flags** — a `enable_private_endpoints` flag actually creates a
      private endpoint. Enforced by the `anti-facade` rule.
- [x] **`fmt` + `validate` clean** — checked per module in CI.
- [x] **`terraform test` coverage** — each changed module has a
      `tests/*.tftest.hcl` exercising defaults and the configured path with
      mocked providers (no live Azure).
- [x] **Outputs are stable maps where collections are involved** — e.g. identity
      `workloads`, storage `container_names`.

## postgres

- [x] `database_name` is **required** (no `"rag"` default).
- [x] `server_extensions` is a list, default `[]` (no `"VECTOR"` default).
- [x] Primary + replica, Entra admin + optional CI/workload admins.
- [x] `enable_private_endpoints` creates **real** `azurerm_private_endpoint`
      resources for primary and replica, with DNS zone group wiring, and
      disables public access.
- [x] Precondition fails fast if private endpoints enabled without a subnet.
- [ ] *Deferred (human apply):* point `private_endpoint_subnet_id` /
      `private_dns_zone_id` at the shared network outputs and apply.

## identity

- [x] `workloads` is a map, default `{}` (no hardcoded upload/embedding/etc.).
- [x] UAMI + OIDC federation per workload via `for_each`.
- [x] `extra_federated_subjects` generalises the old KEDA-operator special case.
- [x] Single `workloads` map output (no fixed per-workload outputs).

## storage

- [x] `containers` set, `role_assignments` map, `lifecycle_rules` list — all
      caller-defined, neutral defaults (no `"documents"` / `documents/processed/`).
- [x] `enable_private_endpoints` creates a **real** blob `azurerm_private_endpoint`
      with DNS wiring and disables public access.
- [x] Secure baseline retained: no shared keys, OAuth default, TLS1_2, no public
      blobs.
- [ ] *Deferred (human apply):* wire subnet/DNS-zone IDs and apply.

## openai

- [x] `openai_user_principal_ids` set, default `[]` (replaces fixed
      worker/retrieval principal vars).
- [x] `enable_private_endpoints` creates a **real** account
      `azurerm_private_endpoint` with DNS wiring and disables public access.
- [x] `local_auth_enabled = false` (Entra-only).
- [ ] *Deferred (human apply):* wire subnet/DNS-zone IDs and apply.

## Shared networking (root `terraform/network.tf`)

- [x] Dedicated VNet, ACA-delegated subnet, private-endpoint subnet.
- [x] Private DNS zones for postgres / blob / openai + VNet links.
- [x] Outputs: vnet id, subnet ids, DNS-zone id map.
- [ ] *Deferred (human apply):* this is the SHARED network — apply is a human
      step (see CHANGELOG), CI never applies.
