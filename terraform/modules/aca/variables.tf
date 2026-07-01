variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "loc_short" { type = string }

# --- Naming (derived from name_prefix/loc_short, overridable) ---
variable "environment_name" {
  description = "Container App Environment name. Empty => derived '<name_prefix>-aca-env-<loc_short>'."
  type        = string
  default     = ""
}

variable "app_name" {
  description = "Container App name. Empty => derived '<name_prefix>-app-<loc_short>'."
  type        = string
  default     = ""
}

variable "container_name" {
  description = "Name of the single container in the app template. Empty => derived '<name_prefix>-app'."
  type        = string
  default     = ""
}

# --- Environment: VNet integration + ingress posture ---
variable "infrastructure_subnet_id" {
  description = "Subnet ID delegated to Microsoft.App/environments. When set the environment is VNet-integrated. Required when internal_ingress_only or zone_redundancy_enabled is true."
  type        = string
  default     = ""
}

variable "internal_ingress_only" {
  description = "When true the environment uses an INTERNAL load balancer (no public ingress); requires infrastructure_subnet_id. This is the production posture for a private-network-only workload."
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy for the environment (requires infrastructure_subnet_id)."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for environment logs. Empty => no workspace wired (Azure default logging)."
  type        = string
  default     = ""
}

variable "workload_profiles" {
  description = "Workload profiles for the environment. Empty list => Consumption-only environment (supports scale-to-zero + VNet integration). Add dedicated profiles (e.g. type 'D4') for reserved capacity."
  type = list(object({
    name          = string
    type          = string
    minimum_count = optional(number)
    maximum_count = optional(number)
  }))
  default = []
}

variable "workload_profile_name" {
  description = "Workload profile the container app runs on. Empty => Consumption. Must match a name in workload_profiles when a dedicated profile is used."
  type        = string
  default     = ""
}

# --- Container app: image + sizing ---
variable "image" {
  description = "Fully-qualified container image reference (e.g. '<registry>/<repo>:<tag>'). Passed as a variable so no registry/solution literal lands in the module."
  type        = string
}

variable "cpu" {
  description = "vCPU allocation for the container (must be a valid Consumption/profile combo with memory)."
  type        = number
  default     = 0.5
}

variable "memory" {
  description = "Memory allocation for the container (e.g. '1Gi'; must pair validly with cpu)."
  type        = string
  default     = "1Gi"
}

# --- Scaling (scale-to-zero by default) ---
variable "min_replicas" {
  description = "Minimum replica count. 0 => scale-to-zero (default) for episodic/event-driven workloads."
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum replica count."
  type        = number
  default     = 1
}

variable "custom_scale_rules" {
  description = "Custom (KEDA) scale rules — e.g. cron, azure-queue, azure-servicebus. Empty => the app relies solely on min/max replicas. A scale-to-zero app with no ingress needs an event source here to scale up in production."
  type = list(object({
    name             = string
    custom_rule_type = string
    metadata         = map(string)
  }))
  default = []
}

# --- Ingress (disabled by default; internal-only when enabled) ---
variable "ingress_enabled" {
  description = "Whether the app exposes HTTP ingress at all. Default false — an episodic agent needs no inbound listener."
  type        = bool
  default     = false
}

variable "ingress_external_enabled" {
  description = "When ingress is enabled, expose it PUBLICLY. Default false => ingress reachable only inside the VNet/environment. Keep false for the private production posture."
  type        = bool
  default     = false
}

variable "ingress_target_port" {
  description = "Container port ingress forwards to (used only when ingress_enabled)."
  type        = number
  default     = 8080
}

# --- Identity, registry, secrets (managed-identity sourced) ---
variable "user_assigned_identity_id" {
  description = "Resource ID of a user-assigned managed identity. Used for (a) the app identity, (b) ACR pull auth, and (c) reading Key Vault secret refs. The CALLER creates the UAMI and grants it AcrPull + Key Vault Secrets User — the module never hardcodes those role scopes."
  type        = string
}

variable "registry_server" {
  description = "Container registry login server (e.g. '<acr>.azurecr.io'). Empty => no registry block (public image). When set, the app authenticates via user_assigned_identity_id."
  type        = string
  default     = ""
}

variable "secrets" {
  description = "Key Vault-backed secrets exposed to the app. Each references a KV secret URI resolved at runtime via user_assigned_identity_id. Reference them from env via secret_env_vars."
  type = list(object({
    name                = string # secret name inside the container app
    key_vault_secret_id = string # KV secret (versionless) URI
  }))
  default = []
}

variable "env_vars" {
  description = "Plain (non-secret) environment variables for the container."
  type        = map(string)
  default     = {}
}

variable "secret_env_vars" {
  description = "Environment variables sourced from a container-app secret: map of ENV_VAR_NAME => secret name (must match a `secrets` entry name)."
  type        = map(string)
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
