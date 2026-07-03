# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

# rao-019 Test Case #4 (Concurrency cap race). What's actually verified
# here: the cap-enforcement LOGIC is correct given a consistent count at
# decision time — a fake in-memory store with no real row locking cannot
# prove the literal simultaneous-thread race is race-free (that needs a
# real database's actual lock semantics, `SELECT ... FOR UPDATE` under
# MySQL/PostgreSQL or SQLite's own serialized-writer model — out of this
# environment's reach). The atomicity *mechanism* itself
# (`.lock` inside one `transaction` block, not a separate check-then-act)
# is what `lib/redmineflux_agentos/engine/concurrency_guard.rb` implements
# for a live instance to actually rely on.
class ConcurrencyGuardTest < ActiveSupport::TestCase
  def setup
    RedminefluxAgentosAgentRun.clear!
  end

  def test_acquires_when_under_both_caps
    run = RedminefluxAgentosAgentRun.create!(status: 'queued', project_id: 1)

    assert RedminefluxAgentos::Engine::ConcurrencyGuard.acquire(run)
    assert_equal 'running', run.status
  end

  def test_denies_at_project_cap_leaving_run_untouched
    cap = RedminefluxAgentos::Engine::ConcurrencyGuard::DEFAULT_PROJECT_CAP
    cap.times { RedminefluxAgentosAgentRun.create!(status: 'running', project_id: 1) }
    run = RedminefluxAgentosAgentRun.create!(status: 'queued', project_id: 1)

    refute RedminefluxAgentos::Engine::ConcurrencyGuard.acquire(run)
    assert_equal 'queued', run.status
  end

  def test_project_cap_does_not_starve_other_projects
    cap = RedminefluxAgentos::Engine::ConcurrencyGuard::DEFAULT_PROJECT_CAP
    cap.times { RedminefluxAgentosAgentRun.create!(status: 'running', project_id: 1) }
    run = RedminefluxAgentosAgentRun.create!(status: 'queued', project_id: 2)

    assert RedminefluxAgentos::Engine::ConcurrencyGuard.acquire(run)
  end

  def test_denies_at_global_cap_even_across_different_projects
    cap = RedminefluxAgentos::Engine::ConcurrencyGuard::DEFAULT_GLOBAL_CAP
    cap.times { |i| RedminefluxAgentosAgentRun.create!(status: 'running', project_id: 100 + i) }
    run = RedminefluxAgentosAgentRun.create!(status: 'queued', project_id: 999)

    refute RedminefluxAgentos::Engine::ConcurrencyGuard.acquire(run)
  end
end
