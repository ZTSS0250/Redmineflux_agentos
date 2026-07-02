# frozen_string_literal: true

module RedminefluxAgentos
  # Prunes execution_logs past the retention window
  # (docs/PHASE4-DATABASE-DESIGN.md §12). MUST exclude any agent_run not in
  # a terminal status (completed/failed/dead/cancelled) regardless of
  # created_at age (rao-009 Gate 3 finding #3) — this is a mandatory
  # implementation requirement, not advisory. Implemented in Phase 16
  # (rao-021, Enterprise Readiness).
  class LogRetentionJob < (defined?(ApplicationJob) ? ApplicationJob : ActiveJob::Base)
    queue_as :agentos_background
    retry_on StandardError, wait: ->(executions) { (executions**2) + 1 }, attempts: 3

    def perform
      raise NotImplementedError, 'LogRetentionJob#perform is implemented in Phase 16 (rao-021)'
    end
  end
end
