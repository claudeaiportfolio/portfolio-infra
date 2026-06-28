# portfolio-infra

Shared **Terraform modules** and shared infrastructure for the
`claudeaiportfolio` repos — the single source of truth for Azure building
blocks. Consuming repos reference the modules via a git-subdirectory source
pinned to a tag (`ref=tf-modules-vX.Y.Z`); only the *invocation* (wiring +
tfvars) lives in the consuming repo (centralise-don't-copy).

## Layout

| Path | What |
|------|------|
| `terraform/modules/` | Reusable Azure modules (see `terraform/modules/README.md`). |
| `terraform/` | Shared root deployment: centrally-owned Auth0 resource servers + the shared private network (`network.tf`). |
| `examples/` | Validate-only, neutral-value invocations of the modules. |
| `tests/` (per module) | `*.tftest.hcl` plan-only tests with mocked providers. |
| `policy/` | Custom Terraform policy gate (`policy_check.py`). |
| `docs/` | Production-readiness checklist. |

## Modules are parameterised — no identifying values

Module bodies contain **no** solution-specific names, secrets, or identifying
values. This is enforced mechanically by the policy gate
(`.github/workflows/terraform-policy.yml`):

- `terraform fmt -check` + `terraform validate` (per module / example / root)
- **custom policy** (`policy/policy_check.py`, BLOCKING):
  - `no-identifying-literals` — fails on hardcoded solution names in module bodies
  - `anti-facade` — a module declaring `enable_private_endpoints` MUST create a
    real `azurerm_private_endpoint`
- `terraform test` (mocked providers, no live Azure)
- `checkov` (advisory)
- plus the shared secret-scan / Claude review gate (`security-review.yml`)

Run the custom policy locally:

```bash
python3 policy/policy_check.py terraform/modules
```

## Versioning

Tag releases as `tf-modules-vX.Y.Z`. Consumers pin to a tag and re-pin
deliberately on their own clock. See `CHANGELOG.md` for interface changes
(notably the breaking **v0.2.0** interface release).
