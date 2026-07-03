# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

class LifecycleTest < ActiveSupport::TestCase
  def setup
    RedminefluxAgentosAgentRun.clear!
    RedminefluxAgentosConfiguration.clear!
  end

  def test_start_transitions_queued_to_running_when_under_cap
    run = RedminefluxAgentosAgentRun.create!(status: 'queued', project_id: 1)

    assert RedminefluxAgentos::Engine::AgentEngine::Lifecycle.transition(run, :start)
    assert_equal 'running', run.status
  end

  # rao-019 Test Case #3 (Pause/Resume) / docs/PHASE8-WORKFLOW-ENGINE-ORCHESTRATION.md
  # §7: paused projects never start new work, but eligible work stays
  # `queued`, not a new error state.
  def test_start_denied_while_project_is_paused
    RedminefluxAgentosConfiguration.set!(project_id: 1, key: 'execution_paused', value: { 'paused' => true })
    run = RedminefluxAgentosAgentRun.create!(status: 'queued', project_id: 1)

    refute RedminefluxAgentos::Engine::AgentEngine::Lifecycle.transition(run, :start)
    assert_equal 'queued', run.status
  end

  def test_start_allowed_again_once_resumed
    RedminefluxAgentosConfiguration.set!(project_id: 1, key: 'execution_paused', value: { 'paused' => true })
    run = RedminefluxAgentosAgentRun.create!(status: 'queued', project_id: 1)
    refute RedminefluxAgentos::Engine::AgentEngine::Lifecycle.transition(run, :start)

    RedminefluxAgentosConfiguration.set!(project_id: 1, key: 'execution_paused', value: { 'paused' => false })

    assert RedminefluxAgentos::Engine::AgentEngine::Lifecycle.transition(run, :start)
    assert_equal 'running', run.status
  end

  def test_pause_on_one_project_does_not_affect_another
    RedminefluxAgentosConfiguration.set!(project_id: 1, key: 'execution_paused', value: { 'paused' => true })
    run = RedminefluxAgentosAgentRun.create!(status: 'queued', project_id: 2)

    assert RedminefluxAgentos::Engine::AgentEngine::Lifecycle.transition(run, :start)
  end

  def test_block_and_clear_cycle
    run = RedminefluxAgentosAgentRun.create!(status: 'running')

    assert RedminefluxAgentos::Engine::AgentEngine::Lifecycle.transition(run, :block)
    assert_equal 'waiting_on_dep', run.status

    assert RedminefluxAgentos::Engine::AgentEngine::Lifecycle.transition(run, :clear)
    assert_equal 'queued', run.status
  end

  def test_record_failure_retries_when_attempts_below_max
    run = RedminefluxAgentosAgentRun.create!(status: 'running', attempts: 0, max_attempts: 3)

    RedminefluxAgentos::Engine::AgentEngine::Lifecycle.record_failure!(run, error_message: 'boom')

    assert_equal 'queued', run.status
    assert_equal 1, run.attempts
    assert_equal 'boom', run.error_message
  end

  def test_record_failure_goes_dead_once_attempts_exhausted
    run = RedminefluxAgentosAgentRun.create!(status: 'running', attempts: 2, max_attempts: 3)

    RedminefluxAgentos::Engine::AgentEngine::Lifecycle.record_failure!(run)

    assert_equal 'dead', run.status
    assert_equal 3, run.attempts
  end

  def test_cancel_from_queued_running_or_waiting_on_dep
    %w[queued running waiting_on_dep].each do |status|
      run = RedminefluxAgentosAgentRun.create!(status: status)
      assert RedminefluxAgentos::Engine::AgentEngine::Lifecycle.transition(run, :cancel), "cancel from #{status}"
      assert_equal 'cancelled', run.status
    end
  end
end
