# frozen_string_literal: true

module RedminefluxAgentos
  class McpToolError
    # The underlying Redmine model rejected the change (e.g.
    # `ActiveRecord::RecordInvalid` from `Issue.create`) —
    # docs/PHASE7-MCP-ARCHITECTURE.md §5. `retryable: false` — the
    # underlying data is invalid, not a transient condition.
    class RedmineValidationError < McpToolError; end
  end
end
