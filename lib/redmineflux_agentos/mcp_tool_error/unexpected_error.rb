# frozen_string_literal: true

module RedminefluxAgentos
  class McpToolError
    # Wraps an unexpected exception from the underlying Redmine call (DB
    # timeout, etc.) — docs/PHASE7-MCP-ARCHITECTURE.md §5. `retryable:
    # true` — matches the agent-run-level retry policy.
    class UnexpectedError < McpToolError
      def initialize(message, original: nil)
        super(message)
        @original = original
      end

      attr_reader :original
    end
  end
end
