# frozen_string_literal: true

module RedminefluxAgentos
  # Executes one agent_run via AgentEngine::Runner
  # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §B.1). Plain ApplicationJob,
  # adapter-agnostic — no assumption about Sidekiq/Resque/Delayed Job
  # (docs/PHASE1-SPECIFICATION.md §7, resolved by redmineflux_devops
  # precedent). Perform body is implemented in Phase 14 (rao-019).
  class AgentRunJob < (defined?(ApplicationJob) ? ApplicationJob : ActiveJob::Base)
    queue_as :agentos_default
    retry_on StandardError, wait: ->(executions) { (executions**2) + 1 }, attempts: 3
    discard_on ActiveRecord::RecordNotFound

    def perform(agent_run_id)
      raise NotImplementedError, 'AgentRunJob#perform is implemented in Phase 14 (rao-019)'
    end
  end
end
