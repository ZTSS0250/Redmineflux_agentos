# frozen_string_literal: true

module RedminefluxAgentos
  module Services
    module Dependencies
      # Seeds the dependency DAG from the default tier chain
      # (docs/AGENTS.md "Agent-to-tier mapping") or an SRS-implied override
      # (WORKFLOW.md §13). Implemented in Phase 14 (rao-019).
      class BuildGraphService < BaseService
        def initialize(project:, ai_tasks:)
          @project = project
          @ai_tasks = ai_tasks
        end

        def call
          raise NotImplementedError, "#{self.class.name}#call is implemented in Phase 14 (rao-019)"
        end
      end
    end
  end
end
