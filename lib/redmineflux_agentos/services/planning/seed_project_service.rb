# frozen_string_literal: true

module RedminefluxAgentos
  module Services
    module Planning
      # Creates the Redmine project via create_project once the SRS is
      # approved (WORKFLOW.md §11). Implemented in Phase 14 (rao-019).
      class SeedProjectService < BaseService
        def initialize(project_plan:, actor:)
          @project_plan = project_plan
          @actor = actor
        end

        def call
          raise NotImplementedError, "#{self.class.name}#call is implemented in Phase 14 (rao-019)"
        end
      end
    end
  end
end
