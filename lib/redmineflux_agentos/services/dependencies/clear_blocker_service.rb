# frozen_string_literal: true

module RedminefluxAgentos
  module Services
    module Dependencies
      # Re-queues any agent_run whose blocking_issue_id just closed
      # (WORKFLOW.md §9/§13). Implemented in Phase 14 (rao-019).
      class ClearBlockerService < BaseService
        def initialize(issue:)
          @issue = issue
        end

        def call
          raise NotImplementedError, "#{self.class.name}#call is implemented in Phase 14 (rao-019)"
        end
      end
    end
  end
end
