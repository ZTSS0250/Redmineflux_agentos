# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

# rao-019 Gate 3 finding #1: one shared contract-conformance test run
# against every agent class, not 17 independent ad hoc tests — catches
# "agent contract drift" (docs/AGENTS.md intro / Liskov Substitution,
# docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.3) in one place.
class AgentContractConformanceTest < ActiveSupport::TestCase
  AGENT_CLASSES = [
    RedminefluxAgentos::Agents::ProjectManagerAgent,
    RedminefluxAgentos::Agents::RequirementAnalystAgent,
    RedminefluxAgentos::Agents::BusinessAnalystAgent,
    RedminefluxAgentos::Agents::ScrumMasterAgent,
    RedminefluxAgentos::Agents::SolutionArchitectAgent,
    RedminefluxAgentos::Agents::DatabaseAgent,
    RedminefluxAgentos::Agents::BackendAgent,
    RedminefluxAgentos::Agents::ApiAgent,
    RedminefluxAgentos::Agents::FrontendAgent,
    RedminefluxAgentos::Agents::UiUxAgent,
    RedminefluxAgentos::Agents::QaAgent,
    RedminefluxAgentos::Agents::SecurityAgent,
    RedminefluxAgentos::Agents::DevopsAgent,
    RedminefluxAgentos::Agents::DeploymentAgent,
    RedminefluxAgentos::Agents::CodeReviewAgent,
    RedminefluxAgentos::Agents::DocumentationAgent,
    RedminefluxAgentos::Agents::ReportingAgent
  ].freeze

  RESERVED_KEYS = %i[code_review].freeze

  def test_exactly_seventeen_agents_registered_in_this_suite
    assert_equal 17, AGENT_CLASSES.size, 'docs/AGENTS.md defines 17 roles (16 active + 1 reserved)'
  end

  def test_every_agent_subclasses_base_agent
    AGENT_CLASSES.each do |klass|
      assert klass < RedminefluxAgentos::Agents::BaseAgent, "#{klass} must subclass BaseAgent"
    end
  end

  def test_every_agent_declares_a_unique_key
    keys = AGENT_CLASSES.map(&:key)
    assert_equal keys.uniq.size, keys.size, 'every agent key must be unique'
    keys.each { |k| assert_kind_of Symbol, k }
  end

  def test_every_active_agent_declares_a_prompt_category
    (AGENT_CLASSES.map(&:key) - RESERVED_KEYS).each do |key|
      klass = AGENT_CLASSES.find { |k| k.key == key }
      assert_kind_of String, klass.prompt_category, "#{klass} (active) must declare .prompt_category"
    end
  end

  def test_reserved_agent_has_no_prompt_category_and_is_rejected_by_registry
    assert_includes AGENT_CLASSES.map(&:key), :code_review
    assert_raises(NotImplementedError) { RedminefluxAgentos::Agents::CodeReviewAgent.prompt_category }

    RedminefluxAgentos::Engine::AgentEngine::Registry.register(RedminefluxAgentos::Agents::CodeReviewAgent)
    assert_raises(ArgumentError) { RedminefluxAgentos::Engine::AgentEngine::Registry.for(:code_review) }
  end

  def test_every_agent_responds_to_call_with_memory_keyword
    AGENT_CLASSES.each do |klass|
      instance_method = klass.instance_method(:call)
      assert_includes instance_method.parameters.map(&:last), :memory,
                       "#{klass}#call must accept the Runner-supplied memory: keyword"
    end
  end
end
