# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)
require 'ostruct'

class DependencyGraphTest < ActiveSupport::TestCase
  def setup
    RedminefluxAgentosDependency.clear!
    Rails.cache.clear
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

  # rao-021 (Phase 16 §B.3): per-project dependency graph snapshot cache,
  # explicit invalidation on both insert (add_edge) and delete
  # (remove_edge, new in rao-021 — nothing removed an edge before this).
  # `edges_for_project` itself queries through `RedminefluxAgentosAiTask`
  # first (matching the pre-rao-021 `DependencyDashboardsController`
  # query shape this method relocated from) — asserting on
  # `Rails.cache.delete` directly, rather than on `edges_for_project`'s
  # return value, tests the invalidation contract without needing real
  # `ai_tasks` fixture rows (this file's existing tests never create any;
  # `add_edge`/`remove_edge` themselves only ever touch `dependencies`).
  def test_remove_edge_deletes_the_row
    task_a = OpenStruct.new(id: 1, project_id: 9)
    task_b = OpenStruct.new(id: 2, project_id: 9)
    RedminefluxAgentos::Engine::DependencyEngine::Graph.add_edge(task_a, depends_on: task_b)
    assert_equal 1, RedminefluxAgentosDependency.where(ai_task_id: 1, depends_on_ai_task_id: 2).count

    RedminefluxAgentos::Engine::DependencyEngine::Graph.remove_edge(task_a, depends_on: task_b)

    assert_equal 0, RedminefluxAgentosDependency.where(ai_task_id: 1, depends_on_ai_task_id: 2).count
  end

  def test_add_edge_invalidates_the_projects_cached_snapshot
    task_a = OpenStruct.new(id: 1, project_id: 9)
    task_b = OpenStruct.new(id: 2, project_id: 9)

    Rails.cache.expects(:delete).with('redmineflux_agentos/dependency_graph/9')

    RedminefluxAgentos::Engine::DependencyEngine::Graph.add_edge(task_a, depends_on: task_b)
  end

  def test_remove_edge_invalidates_the_projects_cached_snapshot
    task_a = OpenStruct.new(id: 3, project_id: 10)
    task_b = OpenStruct.new(id: 4, project_id: 10)
    RedminefluxAgentos::Engine::DependencyEngine::Graph.add_edge(task_a, depends_on: task_b)

    Rails.cache.expects(:delete).with('redmineflux_agentos/dependency_graph/10')

    RedminefluxAgentos::Engine::DependencyEngine::Graph.remove_edge(task_a, depends_on: task_b)
  end

  def test_edges_for_project_reads_through_the_cache_on_a_miss_and_hits_it_after
    RedminefluxAgentosAiTask.expects(:where).with(project_id: 42).once.returns(RedminefluxAgentosAiTask.none)

    RedminefluxAgentos::Engine::DependencyEngine::Graph.edges_for_project(42)
    RedminefluxAgentos::Engine::DependencyEngine::Graph.edges_for_project(42)
  end
end
