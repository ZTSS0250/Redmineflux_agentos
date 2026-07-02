# frozen_string_literal: true

module RedminefluxAgentos
  module Services
    module Requirements
      # Parses a free-text idea into a structured requirement draft,
      # detects gaps against the checklist (docs/PHASE1-SPECIFICATION.md §1.1).
      # Implemented in Phase 14 (rao-019).
      class AnalyzeIdeaService < BaseService
        def initialize(idea_text:, project: nil)
          @idea_text = idea_text
          @project = project
        end

        def call
          raise NotImplementedError, "#{self.class.name}#call is implemented in Phase 14 (rao-019)"
        end
      end
    end
  end
end
