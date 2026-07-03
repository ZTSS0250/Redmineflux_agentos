# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

class ToolRegistryTest < ActiveSupport::TestCase
  def setup
    RedminefluxAgentos::Mcp::ToolRegistry.clear!
  end

  # rao-012 Gate 3 finding #1 / rao-018 Implementation Notes: a tool
  # registered without a params_schema must fail at registration time,
  # not silently accept unvalidated params later.
  def test_register_without_params_schema_raises
    assert_raises(ArgumentError) do
      RedminefluxAgentos::Mcp::ToolRegistry.register(
        :redmineflux_agentos_bad_tool, category: 'test', handler: ->(*) {}, params_schema: {}
      )
    end
  end

  def test_lookup_returns_registered_declaration
    RedminefluxAgentos::Mcp::ToolRegistry.register(
      :redmineflux_agentos_good_tool, category: 'test', handler: ->(*) {}, params_schema: { x: { required: true } }
    )

    declaration = RedminefluxAgentos::Mcp::ToolRegistry.lookup(:redmineflux_agentos_good_tool)
    assert_equal 'test', declaration[:category]
  end

  def test_tools_for_intersects_registered_tools_with_agent_allowlist
    RedminefluxAgentos::Mcp::ToolRegistry.register(
      :redmineflux_agentos_tool_a, category: 'test', handler: ->(*) {}, params_schema: { x: { required: true } }
    )
    RedminefluxAgentos::Mcp::ToolRegistry.register(
      :redmineflux_agentos_tool_b, category: 'test', handler: ->(*) {}, params_schema: { x: { required: true } }
    )

    # allow-list references tool_a plus a tool that was never registered
    # (a stale config) — tools_for must not raise for that, just omit it.
    agent = FakeAgent.new('qa', %i[redmineflux_agentos_tool_a redmineflux_agentos_never_registered])

    assert_equal [:redmineflux_agentos_tool_a], RedminefluxAgentos::Mcp::ToolRegistry.tools_for(agent)
  end
end
