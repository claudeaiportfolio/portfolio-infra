# Shared Auth0 API resource servers, owned centrally here so they can be reused
# across multiple solutions (each solution provisions its OWN M2M client locally
# and is granted scopes on these audiences). Solution-specific clients do NOT
# live here.
auth0_apis = {
  "https://rag.dev.michaelalinks.com" = {
    name           = "RAG MCP"
    token_lifetime = 900 # 15-min access tokens (default would be 86400 / 24h)
    scopes = {
      "ingest:write"  = "Queue a document for embedding + indexing"
      "query:read"    = "Search the indexed corpus and read grounded answers"
      "admin:reindex" = "Force a re-embed of the entire corpus or a tenant"
    }
  }

  # Follow-up: these are currently owned by snowflake-forecasting's own state.
  # Centralise them here (import + state-rm from that repo) to fully realise the
  # "shared APIs central, clients local" model. Left commented so this root's
  # apply doesn't collide with the already-live snowflake-owned resources.
  # "https://snowflake.dev.michaelalinks.com" = {
  #   name = "Loan Portfolio MCP"
  #   scopes = {
  #     "read:forecasts" = "Read loan forecast data"
  #     "read:audit"     = "Read audit log entries"
  #   }
  # }
  # "https://azure.dev.michaelalinks.com" = {
  #   name   = "Azure Resource Graph MCP"
  #   scopes = {}
  # }
}

# M2M / interactive clients are provisioned locally per solution, not here.
# (The interactive `mcp-client` is owned by snowflake-forecasting's state.)
auth0_clients = {}
