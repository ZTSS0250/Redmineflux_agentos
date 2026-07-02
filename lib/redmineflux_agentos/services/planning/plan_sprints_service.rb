# frozen_string_literal: true

module RedminefluxAgentos
  module Services
    module Planning
      # Derives sprints per release, plugin-owned (AD-1, WORKFLOW.md §11).
      # Implemented in Phase 14 (rao-019).
      class PlanSprintsService < BaseService
        def initialize(release:)
          @release = release
        end

        def call
          raise NotImplementedError, "#{self.class.name}#call is implemented in Phase 14 (rao-019)"
        end
      end
    end
  end
end
