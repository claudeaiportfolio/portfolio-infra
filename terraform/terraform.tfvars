auth0_apis = {
  "https://snowflake.dev.michaelalinks.com" = {
    name = "Loan Portfolio MCP"
    scopes = {
      "read:forecasts" = "Read loan forecast data"
      "read:audit"     = "Read audit log entries"
    }
  }
  "https://rag.dev.michaelalinks.com" = {
    name   = "RAG MCP"
    scopes = {}
  }
  "https://azure.dev.michaelalinks.com" = {
    name   = "Azure Resource Graph MCP"
    scopes = {}
  }
}

auth0_clients = {
  "mcp-client" = {
    name        = "MCP Client"
    callbacks   = ["http://localhost:3000/callback"]
    logout_urls = ["http://localhost:3000"]
  }
}
