# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

# rao-021 (Phase 4 §12 / rao-009 Gate 3 finding #3, carried forward as
# mandatory): `debug`-level execution_logs older than the retention
# window are pruned, but never for a non-terminal agent_run regardless
# of age.
class LogRetentionJobTest < ActiveSupport::TestCase
  OLD = RedminefluxAgentos::LogRetentionJob::DEBUG_RETENTION_WINDOW.ago - 1.day
  RECENT = 1.day.ago

  def setup
    RedminefluxAgentosAgentRun.clear!
    RedminefluxAgentosExecutionLog.delete_all
  end

  def test_prunes_old_debug_logs_belonging_to_a_terminal_run
    run = RedminefluxAgentosAgentRun.create!(status: 'completed')
    log = RedminefluxAgentosExecutionLog.create!(agent_run_id: run.id, level: 'debug', message: 'm', created_at: OLD)

    RedminefluxAgentos::LogRetentionJob.new.perform

    refute RedminefluxAgentosExecutionLog.exists?(log.id)
  end

  def test_never_prunes_logs_belonging_to_a_non_terminal_run_regardless_of_age
    %w[queued running waiting_on_dep].each do |status|
      RedminefluxAgentosAgentRun.clear!
      RedminefluxAgentosExecutionLog.delete_all

      run = RedminefluxAgentosAgentRun.create!(status: status)
      log = RedminefluxAgentosExecutionLog.create!(agent_run_id: run.id, level: 'debug', message: 'm', created_at: OLD)

      RedminefluxAgentos::LogRetentionJob.new.perform

      assert RedminefluxAgentosExecutionLog.exists?(log.id),
             "expected a #{status} run's old debug log to survive, but it was pruned"
    end
  end

  def test_does_not_prune_debug_logs_younger_than_the_retention_window
    run = RedminefluxAgentosAgentRun.create!(status: 'completed')
    log = RedminefluxAgentosExecutionLog.create!(agent_run_id: run.id, level: 'debug', message: 'm', created_at: RECENT)

    RedminefluxAgentos::LogRetentionJob.new.perform

    assert RedminefluxAgentosExecutionLog.exists?(log.id)
  end

  def test_never_prunes_non_debug_levels_regardless_of_age
    run = RedminefluxAgentosAgentRun.create!(status: 'dead')
    %w[info warn error].each do |level|
      log = RedminefluxAgentosExecutionLog.create!(agent_run_id: run.id, level: level, message: 'm', created_at: OLD)
      RedminefluxAgentos::LogRetentionJob.new.perform
      assert RedminefluxAgentosExecutionLog.exists?(log.id), "expected #{level}-level log to survive"
    end
  end
end
