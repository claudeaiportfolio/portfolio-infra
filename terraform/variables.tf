variable "auth0_apis" {
  description = "Map of Auth0 resource servers. Key is the API identifier (audience URL)."
  type = map(object({
    name           = string
    token_lifetime = optional(number, 86400)
    allow_offline  = optional(bool, false)
    scopes         = map(string)
  }))
  default = {}
}

variable "auth0_clients" {
  description = "Map of Auth0 applications. Key is a stable logical name."
  type = map(object({
    name                  = string
    app_type              = optional(string, "native")
    callbacks             = optional(list(string), [])
    logout_urls           = optional(list(string), [])
    grant_types           = optional(list(string), ["authorization_code", "refresh_token"])
    authentication_method = optional(string, "none")
    api_identifier        = optional(string, null)
    api_scopes            = optional(list(string), [])
  }))
  default = {}
}

# --- Shared networking (B2) -----------------------------------------------
# Neutral defaults; no identifying values. Override via a git-ignored tfvars
# at apply time.
variable "location" {
  description = "Azure region for the shared network resources."
  type        = string
  default     = "eastus"
}

variable "name_prefix" {
  description = "Short prefix used to name shared resources."
  type        = string
  default     = "portfolio"
}

variable "loc_short" {
  description = "Short region token used in resource names."
  type        = string
  default     = "eus"
}

variable "shared_network_resource_group_name" {
  description = "Resource group for the shared VNet + private DNS zones."
  type        = string
  default     = "portfolio-shared-network-rg"
}

variable "vnet_address_space" {
  description = "Address space for the shared VNet."
  type        = list(string)
  default     = ["10.50.0.0/16"]
}

variable "aca_subnet_prefixes" {
  description = "Address prefixes for the Container Apps delegated subnet (needs at least /23)."
  type        = list(string)
  default     = ["10.50.0.0/23"]
}

variable "private_endpoint_subnet_prefixes" {
  description = "Address prefixes for the private endpoint subnet."
  type        = list(string)
  default     = ["10.50.2.0/24"]
}

variable "tags" {
  description = "Tags applied to shared network resources."
  type        = map(string)
  default     = {}
}
