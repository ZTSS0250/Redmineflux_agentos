# frozen_string_literal: true

module RedminefluxAgentos
  module Mcp
    # Mcp::ToolRegistry — boot-time lookup table mapping each tool name to
    # its declaration (docs/PHASE7-MCP-ARCHITECTURE.md §2). Every entry
    # MUST declare a non-empty `params_schema` — enforced here at boot,
    # not left to convention (rao-012 Gate 3 finding #1). Populated by
    # config/initializers/redmineflux_agentos.rb.
    module ToolRegistry
      @tools = {}

      class << self
        def register(tool_name, category:, handler:, params_schema:, authorize: nil, requires_confirmation: false,
                     read_only: false)
          raise ArgumentError, "#{tool_name}: params_schema must not be empty" if params_schema.blank?

          @tools[tool_name.to_sym] = {
            category: category,
            handler: handler,
            params_schema: params_schema,
            # Layer 1 of the Permission Model (docs/PHASE7-MCP-ARCHITECTURE.md
            # §3) — a `->(actor, params) { true/false }` proc, since only a
            # tool's own registration knows how to resolve its target
            # Project/Issue from `params` (Mcp::Executor stays generic).
            authorize: authorize,
            requires_confirmation: requires_confirmation,
            read_only: read_only
          }
        end

        def lookup(tool_name)
          @tools[tool_name.to_sym]
        end

        # @param agent [RedminefluxAgentosAgent]
        # @return [Array<Symbol>] tool names this agent may call — the
        #   intersection of what's actually registered and the agent's
        #   own declared allow-list (docs/AGENTS.md "tools"). An agent
        #   whose allow-list references a tool that was never registered
        #   (a stale config) never sees it here rather than raising.
        def tools_for(agent)
          allowed = agent.tool_allowlist.map(&:to_sym)
          @tools.keys & allowed
        end

        # Test-only reset — Minitest runs share process state across
        # tests, and registry entries are otherwise boot-time-only.
        def clear!
          @tools = {}
        end
      end
    end
  end
end
