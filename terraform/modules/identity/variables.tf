variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "loc_short" { type = string }
variable "oidc_issuer_url" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
