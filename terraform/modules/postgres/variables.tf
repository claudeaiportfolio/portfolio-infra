variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "loc_short" { type = string }
variable "sku_name" { type = string }
variable "storage_mb" { type = number }
variable "tenant_id" { type = string }
variable "aad_admin_object_id" { type = string }
variable "aad_admin_principal_name" { type = string }
variable "aad_admin_principal_type" { type = string }
variable "ci_admin_object_id" {
  type    = string
  default = ""
}
variable "ci_admin_principal_name" {
  type    = string
  default = ""
}

variable "workload_admins" {
  description = "Per-workload UAMI principals to also register as Microsoft Entra admins."
  type = map(object({
    object_id      = string
    principal_name = string
  }))
  default = {}
}
variable "enable_private_endpoints" { type = bool }
variable "tags" {
  type    = map(string)
  default = {}
}
