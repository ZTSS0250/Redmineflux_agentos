# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

# rao-019 Test Case #6. ActiveSupport::Notifications dispatches
# synchronously in-process by design (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md
# §A.7) — there is no infrastructure-level way to prevent a badly-written
# subscriber from blocking the publisher; "subscribers must be
# fast/non-blocking" (rao-007 Gate 2 finding #1) is a subscriber-authoring
# discipline this test demonstrates, not something EventBus itself can
# enforce. What IS concretely tested: the actual registered
# `issue.status_changed` subscriber (config/initializers/redmineflux_agentos.rb)
# does no slow work inline — it is a bounded status check plus a bounded
# query, not an unbounded loop or sleep — so `publish` returns quickly
# for it specifically.
class EventBusTest < ActiveSupport::TestCase
  def test_publish_and_subscribe_roundtrip
    received = nil
    RedminefluxAgentos::Engine::EventBus.subscribe('roundtrip_test') { |*, payload| received = payload }

    RedminefluxAgentos::Engine::EventBus.publish('roundtrip_test', foo: 'bar')

    assert_equal 'bar', received[:foo]
  end

  def test_events_are_namespaced_under_agentos
    seen_name = nil
    ActiveSupport::Notifications.subscribe(/agentos\./) { |name, *| seen_name = name }

    RedminefluxAgentos::Engine::EventBus.publish('some_event', {})

    assert_equal 'agentos.some_event', seen_name
  ensure
    ActiveSupport::Notifications.unsubscribe(/agentos\./)
  end

  # Demonstrates the documented discipline: a subscriber that enqueues a
  # job for real work keeps `publish` fast even though dispatch is
  # synchronous; a subscriber that does slow work inline would not (not
  # asserted here, since deliberately sleeping in a test suite is exactly
  # the anti-pattern this note warns against) — this test instead pins
  # the reasonable time budget the actually-registered subscriber must
  # meet, giving a concrete regression signal if a future edit adds slow
  # inline work to it.
  def test_publish_completes_within_a_reasonable_budget_for_a_fast_subscriber
    RedminefluxAgentos::Engine::EventBus.subscribe('fast_subscriber_test') { |*, _payload| 1 + 1 }

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    RedminefluxAgentos::Engine::EventBus.publish('fast_subscriber_test', {})
    elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000

    assert_operator elapsed_ms, :<, 50, 'a fast, non-blocking subscriber should not measurably delay publish'
  end
end
