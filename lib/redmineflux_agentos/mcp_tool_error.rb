# frozen_string_literal: true

module RedminefluxAgentos
  # Base of the MCP-specific branch of the exception hierarchy
  # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §B.7). Only the base plus
  # what Phase 13 (rao-018, docs/PHASE7-MCP-ARCHITECTURE.md §5) needs are
  # implemented — `DependencyCycleError`/`ConcurrencyLimitError` belong to
  # whichever ticket (Dependency Engine, Multi-Agent Orchestration)
  # actually exercises them.
  class McpToolError < RedminefluxAgentos::Error; end
end
