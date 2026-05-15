auth0_apis = {
  "https://mcp.dev.michaelalinks.com" = {
    name = "Loan Portfolio MCP"
    scopes = {
      "read:forecasts" = "Read loan forecast data"
      "read:audit"     = "Read audit log entries"
    }
  }
}

auth0_clients = {
  "mcp-client" = {
    name        = "MCP Client"
    callbacks   = ["http://localhost:3000/callback"]
    logout_urls = ["http://localhost:3000"]
  }
}
