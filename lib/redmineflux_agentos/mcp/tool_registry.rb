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
        def register(tool_name, category:, handler:, params_schema:, requires_confirmation: false, read_only: false)
          raise ArgumentError, "#{tool_name}: params_schema must not be empty" if params_schema.blank?

          @tools[tool_name.to_sym] = {
            category: category,
            handler: handler,
            params_schema: params_schema,
            requires_confirmation: requires_confirmation,
            read_only: read_only
          }
        end

        def lookup(tool_name)
          @tools[tool_name.to_sym]
        end

        def tools_for(agent)
          raise NotImplementedError, 'Scoping tools to an agent tool_allowlist is implemented in Phase 13 (rao-018)'
        end
      end
    end
  end
end
