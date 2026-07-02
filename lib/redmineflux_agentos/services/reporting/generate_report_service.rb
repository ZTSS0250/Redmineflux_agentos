# frozen_string_literal: true

module RedminefluxAgentos
  module Services
    module Reporting
      # Generates a status/progress/risk report from dashboard read-models,
      # never by re-deriving from raw LLM calls (docs/AGENTS.md #17,
      # WORKFLOW.md §25). Implemented in Phase 14 (rao-019).
      class GenerateReportService < BaseService
        def initialize(project:, report_type:)
          @project = project
          @report_type = report_type
        end

        def call
          raise NotImplementedError, "#{self.class.name}#call is implemented in Phase 14 (rao-019)"
        end
      end
    end
  end
end
