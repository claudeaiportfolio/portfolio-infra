variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "loc_short" { type = string }
variable "worker_principal_id" { type = string }
variable "retrieval_principal_id" { type = string }
variable "embedding_capacity" { type = number }
variable "chat_capacity" { type = number }
variable "enable_private_endpoints" { type = bool }
variable "tags" {
  type    = map(string)
  default = {}
}
