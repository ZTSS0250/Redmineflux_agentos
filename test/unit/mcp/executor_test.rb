# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

# Covers rao-018's Functional Test table
# (backlog/specification/rao-018-task-phase13-mcp-implementation.md).
#
# Tests Mcp::Executor's own mechanics (permission gates, confirmation
# flow, idempotency, redaction) against a synthetic registered tool,
# never a real Redmine model — Issue/Project/Wiki/TimeEntry/Attachment
# creation via the six tool files needs a live Redmine instance to
# verify, which this suite does not attempt to fake.
class ExecutorTest < ActiveSupport::TestCase
  def setup
    RedminefluxAgentos::Mcp::ToolRegistry.clear!
    FakeMcpToolCall.clear!
    FakeAuditLog.clear!
    @handler_calls = []
  end

  def register_test_tool(overrides = {})
    defaults = {
      category: 'test',
      handler: ->(params, actor) {
        @handler_calls << [params, actor]
        { result: { ok: true }, action: 'test.done', target_type: 'Test', target_id: 1, before: nil, after: { ok: true } }
      },
      params_schema: { value: { required: true } },
      authorize: ->(_actor, _params) { true }
    }
    RedminefluxAgentos::Mcp::ToolRegistry.register(:redmineflux_agentos_test_tool, **defaults.merge(overrides))
  end

  def allowed_user(id = 1)
    FakeUser.new(id, can: true)
  end

  def denied_user(id = 2)
    FakeUser.new(id, can: false)
  end

  # Test Case #1: Permission layer 1 denies.
  def test_permission_layer_1_denies
    register_test_tool(authorize: ->(actor, _params) { actor.can })

    assert_raises(RedminefluxAgentos::McpToolError::PermissionDeniedError) do
      RedminefluxAgentos::Mcp::Executor.call(
        tool_name: :redmineflux_agentos_test_tool, params: { value: 1 }, actor: denied_user, idempotency_key: 'k1'
      )
    end

    assert_empty @handler_calls, 'handler must never run when Layer 1 denies'
    record = FakeMcpToolCall.find_by(idempotency_key: 'k1')
    assert_equal 'failed', record.status
  end

  # Test Case #2: Permission layer 2 (agent tool_allowlist) denies.
  def test_permission_layer_2_denies
    register_test_tool
    agent = FakeAgent.new('qa', [:redmineflux_agentos_other_tool])

    assert_raises(RedminefluxAgentos::McpToolError::PermissionDeniedError) do
      RedminefluxAgentos::Mcp::Executor.call(
        tool_name: :redmineflux_agentos_test_tool, params: { value: 1 }, actor: allowed_user,
        idempotency_key: 'k2', agent: agent
      )
    end

    assert_empty @handler_calls, 'handler must never run when Layer 2 denies'
  end

  # Human-initiated calls (agent: nil) skip Layer 2 entirely.
  def test_layer_2_skipped_for_human_initiated_calls
    register_test_tool

    response = RedminefluxAgentos::Mcp::Executor.call(
      tool_name: :redmineflux_agentos_test_tool, params: { value: 1 }, actor: allowed_user, idempotency_key: 'k3'
    )

    assert_equal :executed, response[:status]
    assert_equal 1, @handler_calls.size
  end

  # Test Case #3: the confirmation gate — pending, not yet executed, then
  # confirmed.
  def test_confirmation_gate_then_confirm
    register_test_tool(requires_confirmation: true)

    response = RedminefluxAgentos::Mcp::Executor.call(
      tool_name: :redmineflux_agentos_test_tool, params: { value: 1 }, actor: allowed_user, idempotency_key: 'k4'
    )
    assert_equal :pending_confirmation, response[:status]
    assert_empty @handler_calls, 'a pending_confirmation tool must not execute yet'

    record = FakeMcpToolCall.find_by(idempotency_key: 'k4')
    assert_equal 'pending_confirmation', record.status

    confirmed = RedminefluxAgentos::Mcp::Executor.confirm(record.id, confirmed_by: allowed_user(9))
    assert_equal :executed, confirmed[:status]
    assert_equal 1, @handler_calls.size
    assert_equal 'executed', FakeMcpToolCall.find(record.id).status
  end

  def test_confirmation_gate_then_reject
    register_test_tool(requires_confirmation: true)

    RedminefluxAgentos::Mcp::Executor.call(
      tool_name: :redmineflux_agentos_test_tool, params: { value: 1 }, actor: allowed_user, idempotency_key: 'k5'
    )
    record = FakeMcpToolCall.find_by(idempotency_key: 'k5')

    rejected = RedminefluxAgentos::Mcp::Executor.reject(record.id, confirmed_by: allowed_user(9))
    assert_equal :rejected, rejected[:status]
    assert_empty @handler_calls, 'a rejected tool call must never execute'
    assert_equal 'rejected', FakeMcpToolCall.find(record.id).status
  end

  # Test Case #4: idempotent retry — no duplicate execution.
  def test_idempotent_retry_does_not_reexecute
    register_test_tool

    first = RedminefluxAgentos::Mcp::Executor.call(
      tool_name: :redmineflux_agentos_test_tool, params: { value: 1 }, actor: allowed_user, idempotency_key: 'same-key'
    )
    second = RedminefluxAgentos::Mcp::Executor.call(
      tool_name: :redmineflux_agentos_test_tool, params: { value: 1 }, actor: allowed_user, idempotency_key: 'same-key'
    )

    assert_equal 1, @handler_calls.size, 'retrying the same idempotency_key must not re-invoke the handler'
    assert_equal first, second
  end

  # Test Case #5: secrets redaction is allow-list based — only params a
  # tool's schema marks `sensitive: true` are redacted in storage; the
  # handler still receives the real value.
  def test_secrets_redaction_is_allow_list_based
    register_test_tool(params_schema: { value: { required: true }, api_key: { required: false, sensitive: true } })

    RedminefluxAgentos::Mcp::Executor.call(
      tool_name: :redmineflux_agentos_test_tool, params: { value: 1, api_key: 'super-secret-token' },
      actor: allowed_user, idempotency_key: 'k6'
    )

    handler_params, = @handler_calls.first
    assert_equal 'super-secret-token', handler_params[:api_key], 'the handler must receive the real value'

    stored = FakeMcpToolCall.find_by(idempotency_key: 'k6')
    refute_includes stored.params_json, 'super-secret-token'
    assert_includes stored.params_json, '[REDACTED]'
    assert_includes stored.params_json, '"value":1', 'non-sensitive params must still be stored in the clear'
  end

  def test_unknown_tool_raises_argument_error
    assert_raises(ArgumentError) do
      RedminefluxAgentos::Mcp::Executor.call(
        tool_name: :redmineflux_agentos_does_not_exist, params: {}, actor: allowed_user, idempotency_key: 'k7'
      )
    end
  end

  def test_missing_required_param_raises_invalid_params_error
    register_test_tool

    assert_raises(RedminefluxAgentos::McpToolError::InvalidParamsError) do
      RedminefluxAgentos::Mcp::Executor.call(
        tool_name: :redmineflux_agentos_test_tool, params: {}, actor: allowed_user, idempotency_key: 'k8'
      )
    end
  end

  def test_read_only_tool_does_not_write_audit_log
    register_test_tool(read_only: true)

    RedminefluxAgentos::Mcp::Executor.call(
      tool_name: :redmineflux_agentos_test_tool, params: { value: 1 }, actor: allowed_user, idempotency_key: 'k9'
    )

    assert_empty FakeAuditLog.records
  end

  def test_write_tool_writes_audit_log
    register_test_tool

    RedminefluxAgentos::Mcp::Executor.call(
      tool_name: :redmineflux_agentos_test_tool, params: { value: 1 }, actor: allowed_user, idempotency_key: 'k10'
    )

    assert_equal 1, FakeAuditLog.records.size
    assert_equal 'test.done', FakeAuditLog.records.first.action
  end

  # rao-021: `agent_run:` is a new optional keyword — before this,
  # `mcp_tool_calls.agent_run_id` was never populated by any call path
  # even though the column/association already existed since rao-016/018.
  # Closing this gap is what lets `NotificationCenter.approval_needed`
  # resolve a project (and so a recipient list) from a
  # `pending_confirmation` row at all (WORKFLOW.md §23).
  def test_agent_run_id_is_stored_when_provided
    register_test_tool
    run = RedminefluxAgentosAgentRun.create!(status: 'running', project_id: 1)

    RedminefluxAgentos::Mcp::Executor.call(
      tool_name: :redmineflux_agentos_test_tool, params: { value: 1 }, actor: allowed_user,
      idempotency_key: 'k11', agent_run: run
    )

    stored = FakeMcpToolCall.find_by(idempotency_key: 'k11')
    assert_equal run.id, stored.agent_run_id
  end

  def test_agent_run_id_is_nil_when_not_provided_backward_compatible
    register_test_tool

    RedminefluxAgentos::Mcp::Executor.call(
      tool_name: :redmineflux_agentos_test_tool, params: { value: 1 }, actor: allowed_user, idempotency_key: 'k12'
    )

    stored = FakeMcpToolCall.find_by(idempotency_key: 'k12')
    assert_nil stored.agent_run_id
  end

  def test_pending_confirmation_publishes_an_event_carrying_the_agent_run
    register_test_tool(requires_confirmation: true)
    run = RedminefluxAgentosAgentRun.create!(status: 'running', project_id: 1)
    received = []
    RedminefluxAgentos::Engine::EventBus.subscribe('mcp_tool_call.pending_confirmation') do |*, payload|
      received << payload[:record]
    end

    RedminefluxAgentos::Mcp::Executor.call(
      tool_name: :redmineflux_agentos_test_tool, params: { value: 1 }, actor: allowed_user,
      idempotency_key: 'k13', agent_run: run
    )

    assert_equal 1, received.size
    assert_equal run.id, received.first.agent_run_id
  end
end
