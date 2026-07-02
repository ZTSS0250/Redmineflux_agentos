# frozen_string_literal: true

module RedminefluxAgentos
  module Services
    module Requirements
      # Produces SRS Markdown + JSON once the confidence threshold is met
      # (docs/PHASE1-SPECIFICATION.md §1.1). Implemented in Phase 14 (rao-019).
      class GenerateSrsService < BaseService
        def initialize(conversation:)
          @conversation = conversation
        end

        def call
          raise NotImplementedError, "#{self.class.name}#call is implemented in Phase 14 (rao-019)"
        end
      end
    end
  end
end
