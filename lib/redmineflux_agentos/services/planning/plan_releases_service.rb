# frozen_string_literal: true

module RedminefluxAgentos
  module Services
    module Planning
      # Derives releases from the approved plan (WORKFLOW.md §11).
      # Implemented in Phase 14 (rao-019).
      class PlanReleasesService < BaseService
        def initialize(project_plan:)
          @project_plan = project_plan
        end

        def call
          raise NotImplementedError, "#{self.class.name}#call is implemented in Phase 14 (rao-019)"
        end
      end
    end
  end
end
