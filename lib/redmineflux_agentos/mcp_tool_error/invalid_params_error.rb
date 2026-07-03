# frozen_string_literal: true

module RedminefluxAgentos
  class McpToolError
    # Params failed `params_schema` validation before the handler ever ran
    # (docs/PHASE7-MCP-ARCHITECTURE.md §4-§5). `retryable: false` —
    # retrying with the same bad params cannot succeed.
    class InvalidParamsError < McpToolError; end
  end
end
