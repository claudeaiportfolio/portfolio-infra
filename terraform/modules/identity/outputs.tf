locals {
  exports = {
    for k, uami in azurerm_user_assigned_identity.this :
    k => {
      name         = uami.name
      id           = uami.id
      client_id    = uami.client_id
      principal_id = uami.principal_id
      namespace    = local.workloads[k].namespace
      sa_name      = local.workloads[k].sa_name
    }
  }
}

output "upload_api" { value = local.exports["upload_api"] }
output "embedding_worker" { value = local.exports["embedding_worker"] }
output "retrieval_api" { value = local.exports["retrieval_api"] }
output "mcp_server" { value = local.exports["mcp_server"] }
