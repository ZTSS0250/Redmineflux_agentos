# frozen_string_literal: true

module RedminefluxAgentos
  module Admin
    # MCP Tools admin screen — enable/disable, edit scopes
    # (docs/PHASE1-SPECIFICATION.md §4.2).
    class McpToolsController < BaseController
      def index
      end

      def update
        head :no_content
      end
    end
  end
end
