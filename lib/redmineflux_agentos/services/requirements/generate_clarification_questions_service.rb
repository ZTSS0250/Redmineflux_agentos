# frozen_string_literal: true

module RedminefluxAgentos
  module Services
    module Requirements
      # Generates one batched clarification question set
      # (docs/PHASE1-SPECIFICATION.md §1.1). Implemented in Phase 14 (rao-019).
      class GenerateClarificationQuestionsService < BaseService
        def initialize(conversation:, gaps_detected:)
          @conversation = conversation
          @gaps_detected = gaps_detected
        end

        def call
          raise NotImplementedError, "#{self.class.name}#call is implemented in Phase 14 (rao-019)"
        end
      end
    end
  end
end
