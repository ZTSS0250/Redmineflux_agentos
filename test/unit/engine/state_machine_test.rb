# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

class StateMachineTest < ActiveSupport::TestCase
  class FakeRecord
    attr_accessor :status, :attempts, :max_attempts

    def initialize(status, attempts: 0, max_attempts: 3)
      @status = status
      @attempts = attempts
      @max_attempts = max_attempts
    end

    def update!(attrs)
      attrs.each { |k, v| public_send("#{k}=", v) }
    end
  end

  TRANSITIONS = [
    { from: :a, to: :b, event: :go },
    { from: :b, to: :c, event: :go, guard: ->(r) { r.attempts < r.max_attempts } }
  ].freeze

  def setup
    @machine = RedminefluxAgentos::Engine::WorkflowEngine::StateMachine.new(transitions: TRANSITIONS,
                                                                             event_prefix: 'test_machine')
  end

  def test_transition_fires_and_updates_status
    record = FakeRecord.new('a')
    assert @machine.transition(record, :go)
    assert_equal 'b', record.status
  end

  def test_guard_blocks_transition_without_mutating_record
    record = FakeRecord.new('b', attempts: 5, max_attempts: 3)
    refute @machine.transition(record, :go)
    assert_equal 'b', record.status
  end

  def test_guard_allows_transition_when_satisfied
    record = FakeRecord.new('b', attempts: 1, max_attempts: 3)
    assert @machine.transition(record, :go)
    assert_equal 'c', record.status
  end

  def test_unknown_event_for_current_status_raises
    record = FakeRecord.new('z')
    assert_raises(ArgumentError) { @machine.transition(record, :go) }
  end

  def test_publishes_an_event_with_from_and_to
    record = FakeRecord.new('a')
    received = nil
    RedminefluxAgentos::Engine::EventBus.subscribe('test_machine.b') { |*, payload| received = payload }

    @machine.transition(record, :go)

    assert_equal record, received[:record]
    assert_equal :a, received[:from]
    assert_equal :b, received[:to]
  end

  def test_custom_event_name_override
    machine = RedminefluxAgentos::Engine::WorkflowEngine::StateMachine.new(
      transitions: TRANSITIONS, event_prefix: 'ignored', event_name: ->(_to) { 'flat_event_name' }
    )
    received = false
    RedminefluxAgentos::Engine::EventBus.subscribe('flat_event_name') { received = true }

    machine.transition(FakeRecord.new('a'), :go)

    assert received, 'event_name override should replace the default per-status naming'
  end

  def test_custom_status_reader_and_writer
    issue_like = Struct.new(:label).new('a')
    machine = RedminefluxAgentos::Engine::WorkflowEngine::StateMachine.new(
      transitions: TRANSITIONS, event_prefix: 'custom',
      status_reader: ->(r) { r.label.to_sym }, status_writer: ->(r, s) { r.label = s.to_s }
    )

    assert machine.transition(issue_like, :go)
    assert_equal 'b', issue_like.label
  end
end
