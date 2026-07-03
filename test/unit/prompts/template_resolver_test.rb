# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)
require 'ostruct'

class TemplateResolverTest < ActiveSupport::TestCase
  def setup
    RedminefluxAgentosPromptTemplate.clear!
    Rails.cache.clear
  end

  def test_resolves_shared_template_with_interpolation
    RedminefluxAgentosPromptTemplate.create!(key: 'greeting.default', agent_id: nil, is_active: true,
                                              content: 'Hello {{name}}', variables_json: ['name'].to_json)

    result = RedminefluxAgentos::Prompts::TemplateResolver.resolve('greeting.default', variables: { 'name' => 'World' })

    assert_equal 'Hello World', result
  end

  def test_role_specific_template_takes_precedence_over_shared
    RedminefluxAgentosPromptTemplate.create!(key: 'greeting.default', agent_id: nil, is_active: true,
                                              content: 'Shared', variables_json: [].to_json)
    RedminefluxAgentosPromptTemplate.create!(key: 'greeting.default', agent_id: 7, is_active: true,
                                              content: 'Role-specific', variables_json: [].to_json)
    agent = OpenStruct.new(id: 7)

    result = RedminefluxAgentos::Prompts::TemplateResolver.resolve('greeting.default', agent: agent, variables: {})

    assert_equal 'Role-specific', result
  end

  def test_falls_back_to_shared_when_agent_has_no_role_specific_row
    RedminefluxAgentosPromptTemplate.create!(key: 'greeting.default', agent_id: nil, is_active: true,
                                              content: 'Shared', variables_json: [].to_json)
    agent = OpenStruct.new(id: 999)

    result = RedminefluxAgentos::Prompts::TemplateResolver.resolve('greeting.default', agent: agent, variables: {})

    assert_equal 'Shared', result
  end

  def test_missing_template_raises_prompt_variable_missing_error
    assert_raises(RedminefluxAgentos::PromptVariableMissingError) do
      RedminefluxAgentos::Prompts::TemplateResolver.resolve('does_not_exist.default', variables: {})
    end
  end

  def test_missing_required_variable_raises
    RedminefluxAgentosPromptTemplate.create!(key: 'needs_var.default', agent_id: nil, is_active: true,
                                              content: '{{required_field}}', variables_json: ['required_field'].to_json)

    assert_raises(RedminefluxAgentos::PromptVariableMissingError) do
      RedminefluxAgentos::Prompts::TemplateResolver.resolve('needs_var.default', variables: {})
    end
  end

  def test_inactive_template_is_not_resolved
    RedminefluxAgentosPromptTemplate.create!(key: 'stale.default', agent_id: nil, is_active: false,
                                              content: 'Old', variables_json: [].to_json)

    assert_raises(RedminefluxAgentos::PromptVariableMissingError) do
      RedminefluxAgentos::Prompts::TemplateResolver.resolve('stale.default', variables: {})
    end
  end

  # rao-021 (Phase 16 §B.3): explicit-invalidation cache on the active
  # template per key. `Admin::PromptTemplatesController#activate!`/
  # `#create_new_draft!` both call `invalidate!` after their transaction
  # commits — these tests exercise `TemplateResolver` directly, the same
  # boundary that controller actually calls across.
  def test_resolve_only_queries_once_across_repeated_calls
    RedminefluxAgentosPromptTemplate.create!(key: 'cached.default', agent_id: nil, is_active: true,
                                              content: 'v1', variables_json: [].to_json)
    # Captured BEFORE `expects` stubs the method — calling the real
    # `.where` as part of setting up its own stub's `.returns(...)` value
    # would count as an invocation against the `.once` limit set up on
    # the very next line, always failing "invoked twice" regardless of
    # how many times the code under test actually calls it.
    real_scope = RedminefluxAgentosPromptTemplate.where(key: 'cached.default', is_active: true)

    RedminefluxAgentosPromptTemplate.expects(:where).with(key: 'cached.default', is_active: true)
                                     .once.returns(real_scope)

    2.times { RedminefluxAgentos::Prompts::TemplateResolver.resolve('cached.default', variables: {}) }
  end

  def test_invalidate_forces_a_fresh_read_reflecting_a_newly_activated_version
    RedminefluxAgentosPromptTemplate.create!(key: 'versioned.default', agent_id: nil, version: 1, is_active: true,
                                              content: 'v1', variables_json: [].to_json)
    assert_equal 'v1', RedminefluxAgentos::Prompts::TemplateResolver.resolve('versioned.default', variables: {})

    # Same shape as Admin::PromptTemplatesController#activate!: deactivate
    # the old row, activate a new one, for the SAME key.
    RedminefluxAgentosPromptTemplate.where(key: 'versioned.default', is_active: true).update_all(is_active: false)
    RedminefluxAgentosPromptTemplate.create!(key: 'versioned.default', agent_id: nil, version: 2, is_active: true,
                                              content: 'v2', variables_json: [].to_json)
    RedminefluxAgentos::Prompts::TemplateResolver.invalidate!('versioned.default')

    assert_equal 'v2', RedminefluxAgentos::Prompts::TemplateResolver.resolve('versioned.default', variables: {})
  end

  def test_without_invalidate_the_stale_version_keeps_being_served
    RedminefluxAgentosPromptTemplate.create!(key: 'stale_cache.default', agent_id: nil, version: 1, is_active: true,
                                              content: 'v1', variables_json: [].to_json)
    assert_equal 'v1', RedminefluxAgentos::Prompts::TemplateResolver.resolve('stale_cache.default', variables: {})

    RedminefluxAgentosPromptTemplate.where(key: 'stale_cache.default', is_active: true).update_all(is_active: false)
    RedminefluxAgentosPromptTemplate.create!(key: 'stale_cache.default', agent_id: nil, version: 2, is_active: true,
                                              content: 'v2', variables_json: [].to_json)
    # No invalidate! call here.

    assert_equal 'v1', RedminefluxAgentos::Prompts::TemplateResolver.resolve('stale_cache.default', variables: {}),
                 'without invalidate!, the cache must keep serving the pre-activation version'
  end
end
