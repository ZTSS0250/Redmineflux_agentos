# frozen_string_literal: true

module RedminefluxAgentos
  # Daily cost_trackings aggregation from token_usages
  # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §B.1,
  # docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §10). Implemented in
  # Phase 14 (rao-019).
  class CostRollupJob < (defined?(ApplicationJob) ? ApplicationJob : ActiveJob::Base)
    queue_as :agentos_background
    retry_on StandardError, wait: ->(executions) { (executions**2) + 1 }, attempts: 3

    def perform
      raise NotImplementedError, 'CostRollupJob#perform is implemented in Phase 14 (rao-019)'
    end
  end
end
