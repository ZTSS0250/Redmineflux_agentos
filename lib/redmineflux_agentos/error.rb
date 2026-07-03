# frozen_string_literal: true

module RedminefluxAgentos
  # Base of the plugin-wide exception hierarchy
  # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §B.7) so a top-level rescue
  # (AgentEngine::Runner, ApplicationController) can classify any
  # AgentOS-originated failure with one `rescue RedminefluxAgentos::Error`.
  #
  # Only the base class plus what Phase 12 (rao-017, the Mock Provider)
  # needs are implemented here — `McpToolError`, `DependencyCycleError`, and
  # `ConcurrencyLimitError` belong to whichever later phase (MCP
  # Implementation / Multi-Agent Orchestration) actually exercises them.
  class Error < StandardError; end
end
