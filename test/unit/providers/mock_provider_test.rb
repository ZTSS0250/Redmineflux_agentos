# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

# Covers rao-017's Unit Test table (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md,
# backlog/specification/rao-017-task-phase12-mock-provider-implementation.md).
class MockProviderTest < ActiveSupport::TestCase
  def setup
    @provider = RedminefluxAgentos::Providers::Mock::MockProvider.new
  end

  def base_request(overrides = {})
    {
      agent_key: 'project_manager',
      prompt_category: 'project_planning',
      scenario_key: 'create_project',
      variables: { 'project_name' => 'EMS', 'module_list' => 'Leave, Attendance' },
      idempotency_key: 'test-key'
    }.merge(overrides)
  end

  # rao-017 Test Case #1 / Gate 2 finding #1: the zero-egress invariant
  # (docs/SECURITY-COMPLIANCE-OVERVIEW.md §3) is a tested invariant, not a
  # code-review-only rule.
  def test_zero_network_calls
    TCPSocket.expects(:open).never
    Net::HTTP.any_instance.expects(:start).never

    @provider.request(base_request)
  end

  # rao-017 Test Case #2 / rao-008 Gate 3 finding #2: the same fixture
  # rendered twice — once in isolation, once inside a batch — is
  # byte-identical both times.
  def test_determinism_isolated_and_batched
    isolated = @provider.request(base_request)
    batched = 3.times.map { @provider.request(base_request) }.last

    assert_equal isolated[:content], batched[:content]
    assert_equal isolated[:usage], batched[:usage]
    assert_equal isolated[:tool_calls].map { |c| c[:params] }, batched[:tool_calls].map { |c| c[:params] }
  end

  # rao-017 Test Case #3: a turn producing multiple tool_calls gets a
  # distinct {idempotency_key}-{n} per call — never the same raw key
  # reused across calls (§2.1/§2.5).
  def test_multi_tool_call_idempotency_suffixing
    response = @provider.request(base_request(
                                    prompt_category: 'release_planning',
                                    scenario_key: 'release_planning',
                                    variables: { 'release_count' => 2, 'constraints' => 'none' }
                                  ))

    assert_equal 2, response[:tool_calls].size
    assert_equal %w[test-key-0 test-key-1], response[:tool_calls].map { |c| c[:idempotency_key] }
  end

  # rao-017 Test Case #5: a round-qualified scenario_key resolves the
  # correct round's content, not round 1's (§7).
  def test_round_qualified_fixture_selection
    round1 = @provider.request(base_request(
                                  agent_key: 'requirement_analyst',
                                  prompt_category: 'clarification_questions',
                                  scenario_key: 'clarification_questions',
                                  variables: { 'idea_text' => 'EMS', 'gaps_detected' => 'x', 'round_number' => 1 }
                                ))
    round2 = @provider.request(base_request(
                                  agent_key: 'requirement_analyst',
                                  prompt_category: 'clarification_questions',
                                  scenario_key: 'clarification_questions',
                                  variables: { 'idea_text' => 'EMS', 'gaps_detected' => 'x', 'round_number' => 2 }
                                ))

    refute_equal round1[:content], round2[:content]
    assert_includes round1[:content], 'round 1 of 3'
    assert_includes round2[:content], 'round 2 of 3'
  end

  # §8.5: a scenario with no fixture of its own completes with a
  # human-visible "not yet covered" message, not an unhandled exception.
  def test_unknown_scenario_falls_back_without_raising
    response = @provider.request(base_request(
                                    prompt_category: 'not_a_real_category',
                                    scenario_key: 'nope',
                                    variables: {}
                                  ))

    assert_equal "This scenario is not yet covered by the Mock Provider's fixture set.", response[:content]
  end

  # §8.2 / the `variable_missing` error_code (§2.3): a fixture referencing
  # a variable the caller didn't provide raises a classified error, not a
  # generic NoMethodError/nil interpolation.
  def test_missing_variable_raises_prompt_variable_missing_error
    assert_raises(RedminefluxAgentos::PromptVariableMissingError) do
      @provider.request(base_request(variables: {}))
    end
  end

  # §7.2: Ticket Creation is a deterministic generation RULE, not a static
  # fixture — the same epic always produces the same story/task set.
  def test_ticket_generation_rule_is_deterministic
    request = base_request(
      prompt_category: 'ticket_generation',
      scenario_key: 'ticket_generation',
      variables: { 'epic_title' => 'Payroll Module', 'epic' => { 'title' => 'Payroll Module', 'module' => 'payroll' } }
    )

    first = @provider.request(request)
    second = @provider.request(request)

    assert_equal 9, first[:tool_calls].size # 3 stories x (1 story + 2 tasks)
    assert_equal first[:tool_calls].map { |c| c[:params] }, second[:tool_calls].map { |c| c[:params] }
  end

  def test_capabilities_shape
    caps = @provider.capabilities

    assert caps[:supports_tool_calling]
    refute caps[:supports_streaming]
    assert_equal 11, caps[:supported_categories].size
  end
end
