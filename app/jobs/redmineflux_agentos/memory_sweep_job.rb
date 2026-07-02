# frozen_string_literal: true

module RedminefluxAgentos
  # Expires short_term agent memory past its expires_at
  # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.9). Implemented in
  # Phase 14 (rao-019).
  class MemorySweepJob < (defined?(ApplicationJob) ? ApplicationJob : ActiveJob::Base)
    queue_as :agentos_background
    retry_on StandardError, wait: ->(executions) { (executions**2) + 1 }, attempts: 3

    def perform
      raise NotImplementedError, 'MemorySweepJob#perform is implemented in Phase 14 (rao-019)'
    end
  end
end
