# frozen_string_literal: true

module RedminefluxAgentos
  module Services
    module Tickets
      # Decomposes an epic into stories/tasks/subtasks per the deterministic
      # Fake Ticket Generation rule in v1 (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md
      # §7.2), acceptance criteria, story points, labels (WORKFLOW.md §12).
      # Implemented in Phase 14 (rao-019).
      class GenerateTicketsService < BaseService
        def initialize(epic:, agent:)
          @epic = epic
          @agent = agent
        end

        def call
          raise NotImplementedError, "#{self.class.name}#call is implemented in Phase 14 (rao-019)"
        end
      end
    end
  end
end
