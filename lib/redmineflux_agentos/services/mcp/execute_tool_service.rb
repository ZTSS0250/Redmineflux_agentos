# frozen_string_literal: true

module RedminefluxAgentos
  module Services
    module Mcp
      # Thin service-layer wrapper around RedminefluxAgentos::Mcp::Executor
      # for callers that prefer the service-object convention
      # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.2) over calling the
      # module directly. Implemented in Phase 13 (rao-018).
      class ExecuteToolService < BaseService
        def initialize(tool_name:, params:, actor:, idempotency_key:)
          @tool_name = tool_name
          @params = params
          @actor = actor
          @idempotency_key = idempotency_key
        end

        def call
          raise NotImplementedError, "#{self.class.name}#call is implemented in Phase 13 (rao-018)"
        end
      end
    end
  end
end
