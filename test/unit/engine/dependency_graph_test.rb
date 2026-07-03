# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)
require 'ostruct'

class DependencyGraphTest < ActiveSupport::TestCase
  def setup
    RedminefluxAgentosDependency.clear!
  end

  def test_add_edge_creates_a_dependency_row
    task_a = OpenStruct.new(id: 1)
    task_b = OpenStruct.new(id: 2)

    RedminefluxAgentos::Engine::DependencyEngine::Graph.add_edge(task_a, depends_on: task_b)

    assert_equal 1, RedminefluxAgentosDependency.where(ai_task_id: 1, depends_on_ai_task_id: 2).count
  end

  def test_direct_cycle_is_rejected
    task_a = OpenStruct.new(id: 1)
    task_b = OpenStruct.new(id: 2)
    RedminefluxAgentos::Engine::DependencyEngine::Graph.add_edge(task_a, depends_on: task_b)

    assert_raises(RedminefluxAgentos::DependencyCycleError) do
      RedminefluxAgentos::Engine::DependencyEngine::Graph.add_edge(task_b, depends_on: task_a)
    end
  end

  def test_transitive_cycle_is_rejected
    a, b, c = [1, 2, 3].map { |id| OpenStruct.new(id: id) }
    RedminefluxAgentos::Engine::DependencyEngine::Graph.add_edge(a, depends_on: b) # a -> b
    RedminefluxAgentos::Engine::DependencyEngine::Graph.add_edge(b, depends_on: c) # b -> c

    assert_raises(RedminefluxAgentos::DependencyCycleError) do
      RedminefluxAgentos::Engine::DependencyEngine::Graph.add_edge(c, depends_on: a) # would close a -> b -> c -> a
    end
  end

  def test_self_dependency_is_rejected
    a = OpenStruct.new(id: 1)

    assert_raises(RedminefluxAgentos::DependencyCycleError) do
      RedminefluxAgentos::Engine::DependencyEngine::Graph.add_edge(a, depends_on: a)
    end
  end

  def test_unrelated_edges_do_not_conflict
    a, b, c, d = [1, 2, 3, 4].map { |id| OpenStruct.new(id: id) }
    RedminefluxAgentos::Engine::DependencyEngine::Graph.add_edge(a, depends_on: b)

    assert RedminefluxAgentos::Engine::DependencyEngine::Graph.add_edge(c, depends_on: d)
  end
end
