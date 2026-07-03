# frozen_string_literal: true

module RedminefluxAgentos
  # Prunes `execution_logs` past their retention window
  # (docs/PHASE4-DATABASE-DESIGN.md §12): `debug`-level rows older than
  # `DEBUG_RETENTION_WINDOW` are deleted; `info`/`warn`/`error` are kept
  # indefinitely (the level filter below only ever matches `debug` rows).
  #
  # Never touches a non-terminal `agent_run`'s logs regardless of age
  # (rao-009 Gate 3 finding #3, carried forward as mandatory into
  # rao-021) — a long-`waiting_on_dep` run's `created_at` can be old, but
  # its logs must survive until the run itself finishes. Excluded via a
  # SQL subquery (`RedminefluxAgentosAgentRun::TERMINAL_STATUSES`), not a
  # `pluck` into a Ruby array, so this stays one DELETE statement
  # regardless of how many non-terminal runs currently exist
  # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §B.9's no-N+1 ethos
  # generalized to batch jobs).
  class LogRetentionJob < (defined?(ApplicationJob) ? ApplicationJob : ActiveJob::Base)
    queue_as :agentos_background
    retry_on StandardError, wait: ->(executions) { (executions**2) + 1 }, attempts: 3

    DEBUG_RETENTION_WINDOW = 90.days

    def perform(now = Time.current)
      cutoff = now - DEBUG_RETENTION_WINDOW
      non_terminal_runs = RedminefluxAgentosAgentRun.where.not(status: RedminefluxAgentosAgentRun::TERMINAL_STATUSES)
                                                     .select(:id)

      RedminefluxAgentosExecutionLog
        .where(level: 'debug')
        .where('created_at < ?', cutoff)
        .where.not(agent_run_id: non_terminal_runs)
        .delete_all
    end
  end
end
