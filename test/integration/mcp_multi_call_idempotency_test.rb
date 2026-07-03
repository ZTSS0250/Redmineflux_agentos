# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

# Integration test across rao-017 (Mock Provider) and rao-018 (Mcp::Executor):
# a Mock Provider response's multiple `tool_calls`, each already
# index-suffixed (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §2.1/§2.5),
# feed correctly into Mcp::Executor's own idempotency dedup (§4) — every
# distinct suffixed key executes once, and retrying the SAME suffixed key
# (simulating a retried agent_run re-attempting one call from the batch)
# never re-executes.
class McpMultiCallIdempotencyTest < ActiveSupport::TestCase
  def setup
    RedminefluxAgentos::Mcp::ToolRegistry.clear!
    FakeMcpToolCall.clear!
    @handler_calls = []

    RedminefluxAgentos::Mcp::ToolRegistry.register(
      :redmineflux_agentos_create_issue,
      category: 'ticket_generation',
      handler: ->(params, actor) {
        @handler_calls << params
        # Mock Provider fixtures produce string-keyed params (§7's YAML
        # shape) — a real handler reads through Support.param for this
        # reason; this synthetic handler does the same check inline
        # rather than pulling in the full Support module for one field.
        subject = params[:subject] || params['subject']
        { result: { id: @handler_calls.size, subject: subject }, action: 'issue.created',
          target_type: 'Issue', target_id: @handler_calls.size, before: nil, after: { subject: subject } }
      },
      params_schema: { subject: { required: true } },
      authorize: ->(_actor, _params) { true }
    )
  end

  def test_provider_style_tool_calls_execute_once_each_and_retries_dedupe
    provider = RedminefluxAgentos::Providers::Mock::MockProvider.new
    fixture = {
      'tool_calls' => [
        { 'tool_name' => 'redmineflux_agentos_create_issue', 'params' => { 'subject' => 'Story 1' } },
        { 'tool_name' => 'redmineflux_agentos_create_issue', 'params' => { 'subject' => 'Story 2' } },
        { 'tool_name' => 'redmineflux_agentos_create_issue', 'params' => { 'subject' => 'Story 3' } }
      ]
    }
    response = provider.send(:build_response, fixture, { idempotency_key: 'turn-42' })
    assert_equal %w[turn-42-0 turn-42-1 turn-42-2], response[:tool_calls].map { |c| c[:idempotency_key] }

    actor = FakeUser.new(1, can: true)
    response[:tool_calls].each do |call|
      RedminefluxAgentos::Mcp::Executor.call(
        tool_name: call[:tool_name], params: call[:params], actor: actor, idempotency_key: call[:idempotency_key]
      )
    end
    assert_equal 3, @handler_calls.size, 'three distinct suffixed keys must each execute exactly once'

    # A retried agent_run re-attempts call index 1 with the SAME suffixed key.
    retried = response[:tool_calls][1]
    RedminefluxAgentos::Mcp::Executor.call(
      tool_name: retried[:tool_name], params: retried[:params], actor: actor, idempotency_key: retried[:idempotency_key]
    )
    assert_equal 3, @handler_calls.size, 'retrying the same suffixed key must not create a duplicate Redmine record'
  end
end
