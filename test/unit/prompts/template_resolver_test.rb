# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)
require 'ostruct'

class TemplateResolverTest < ActiveSupport::TestCase
  def setup
    RedminefluxAgentosPromptTemplate.clear!
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
end
