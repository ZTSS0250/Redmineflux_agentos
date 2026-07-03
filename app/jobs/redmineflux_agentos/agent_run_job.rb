# frozen_string_literal: true

module RedminefluxAgentos
  # Executes one agent_run via AgentEngine::Runner
  # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §B.1). Plain ApplicationJob,
  # adapter-agnostic — no assumption about Sidekiq/Resque/Delayed Job
  # (docs/PHASE1-SPECIFICATION.md §7, resolved by redmineflux_devops
  # precedent).
  #
  # `Runner.execute` itself never raises for an ordinary agent-side
  # failure — it classifies those into the `agent_runs.failed/dead`
  # transition (WORKFLOW.md §8) via `Lifecycle.record_failure!`. This
  # job's own `retry_on`/`discard_on` are the separate, job-infrastructure
  # retry layer (Phase 2 §B.4's second of three layers) for something
  # `Runner.execute` didn't even get to run for — e.g. the job framework
  # itself failing to load/deserialize `agent_run_id`.
  class AgentRunJob < (defined?(ApplicationJob) ? ApplicationJob : ActiveJob::Base)
    queue_as :agentos_default
    retry_on StandardError, wait: ->(executions) { (executions**2) + 1 }, attempts: 3
    discard_on ActiveRecord::RecordNotFound

    def perform(agent_run_id)
      agent_run = RedminefluxAgentosAgentRun.find(agent_run_id)
      RedminefluxAgentos::Engine::AgentEngine::Runner.execute(agent_run)
    end
  end
end
