# frozen_string_literal: true

module RedminefluxAgentos
  class McpToolError
    # Either Permission Model layer denied the call
    # (docs/PHASE7-MCP-ARCHITECTURE.md §3) — Layer 1 (Redmine's own
    # `authorize?` for the acting `User.current`) or Layer 2 (the calling
    # agent's `tool_allowlist`). `retryable: false` — neither layer's
    # denial is transient (§5).
    class PermissionDeniedError < McpToolError; end
  end
end
