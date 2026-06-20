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

  "https://snowflake.dev.michaelalinks.com" = {
    name = "Loan Portfolio MCP"
    scopes = {
      "read:forecasts" = "Read loan forecast data"
      "read:audit"     = "Read audit log entries"
    }
  }

  # Follow-up: the azure API ("Azure Resource Graph MCP") isn't live anywhere
  # yet; add it here when a solution actually needs it.
  # "https://azure.dev.michaelalinks.com" = {
  #   name   = "Azure Resource Graph MCP"
  #   scopes = {}
  # }
}

# Shared interactive client (used across solutions, e.g. claude.ai connecting to
# the MCP servers) is owned centrally. Solution-specific M2M clients stay LOCAL
# in their repos (rag-m2m in rag-ingestion-platform, snowflake-subagent in
# snowflake-forecasting).
auth0_clients = {
  "mcp-client" = {
    name        = "MCP Client"
    app_type    = "native"
    callbacks   = ["http://localhost:3000/callback", "https://claude.ai/api/mcp/auth_callback"]
    logout_urls = ["http://localhost:3000"]
  }
}
