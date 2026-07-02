# frozen_string_literal: true

module RedminefluxAgentos
  module Mcp
    # Mcp::Executor — the single write path to Redmine for every AgentOS
    # action (docs/PHASE7-MCP-ARCHITECTURE.md §1). Owns the Permission
    # Model's two independent layers, the confirmation gate, idempotency-key
    # suffixing for multi-call turns, and audit logging. Phase 13 (rao-018)
    # implements the body; this is the interface skeleton.
    module Executor
      # @param tool_name [Symbol, String]
      # @param params [Hash]
      # @param actor [User] required, never defaulted — Phase 2 §B.8. For
      #   agent-initiated calls this is the AgentOS System user
      #   (rao-015, docs/PHASE7-MCP-ARCHITECTURE.md §3); for human-initiated
      #   calls it's the real logged-in user.
      # @param idempotency_key [String]
      def self.call(tool_name:, params:, actor:, idempotency_key:)
        raise NotImplementedError, 'MCP tool execution is implemented in Phase 13 (rao-018)'
      end
    end
  end
end
