# Shared Terraform modules

Reusable Azure building-block modules for the `claudeaiportfolio` repos. These
are the **single source of truth** — consuming repos reference them via a
git-subdirectory source pinned to a tag, rather than copying modules per repo
(centralise-don't-copy).

## Consuming a module

```hcl
module "postgres" {
  source = "git::https://github.com/claudeaiportfolio/portfolio-infra.git//terraform/modules/postgres?ref=tf-modules-v0.1.0"
  # ...inputs
}
```

Only the **invocation** (wiring + tfvars) lives in the consuming repo; the
module definition lives here.

## Modules

| Module | Purpose |
|--------|---------|
| `auth0` | Auth0 resource servers (APIs), clients (incl. M2M), grants, KV secret sync |
| `identity` | User-assigned managed identities + OIDC federation for workloads |
| `storage` | Storage account + role assignments for workload principals |
| `postgres` | Postgres flexible server (+ replica) with Entra admin registration |
| `openai` | Azure OpenAI account + model deployments + role assignments |
| `aks-nodepool` | Spot user node pool attached to a shared AKS cluster |

## Versioning

Tag releases as `tf-modules-vX.Y.Z`. Consumers pin to a tag; bump the pin
deliberately. Modules are parameterised — no identifying values are hardcoded.
