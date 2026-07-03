# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    module DependencyEngine
      # DependencyEngine::Graph — builds/validates the DAG of
      # RedminefluxAgentosDependency edges, with an application-level cycle
      # check at insert time (docs/DATABASE-SCHEMA.md — no DB-level cycle
      # constraint is expressible for a graph).
      #
      # rao-021 (Phase 16 §B.3): this is also the sole read/write entry
      # point for a project's dependency graph, so it's where the "per-
      # project dependency graph snapshot" `Rails.cache` entry lives —
      # `add_edge`/`remove_edge` are the only two things that can change a
      # project's edge set, so invalidating from both, and only both, is
      # sufficient (rao-021 QA Test Case #1: add then remove, no stale
      # cache either way). `remove_edge` did not exist before rao-021 —
      # `add_edge` had no delete counterpart anywhere in the codebase, so
      # there was nothing to invalidate the missing "delete" trigger
      # against; adding it here is this ticket's own caching requirement,
      # not scope creep, since a "delete invalidation" test case is
      # meaningless without a delete path to invalidate on.
      module Graph
        class << self
          # @param ai_task [RedminefluxAgentosAiTask] the dependent task
          # @param depends_on [RedminefluxAgentosAiTask] the prerequisite
          # @raise [RedminefluxAgentos::DependencyCycleError] if `depends_on`
          #   can already (transitively) reach `ai_task` — adding this edge
          #   would close a cycle
          def add_edge(ai_task, depends_on:)
            if creates_cycle?(ai_task, depends_on)
              raise RedminefluxAgentos::DependencyCycleError,
                    "Adding an edge #{ai_task.id} -> #{depends_on.id} would create a dependency cycle"
            end

            edge = RedminefluxAgentosDependency.create!(
              ai_task_id: ai_task.id, depends_on_ai_task_id: depends_on.id, dependency_type: 'blocks'
            )
            invalidate!(ai_task.project_id)
            edge
          end

          # @param ai_task [RedminefluxAgentosAiTask] the dependent task
          # @param depends_on [RedminefluxAgentosAiTask] the prerequisite
          def remove_edge(ai_task, depends_on:)
            RedminefluxAgentosDependency.where(
              ai_task_id: ai_task.id, depends_on_ai_task_id: depends_on.id
            ).destroy_all
            invalidate!(ai_task.project_id)
          end

          # @param project_id [Integer]
          # @return [Array<RedminefluxAgentosDependency>] every edge among
          #   `project_id`'s tasks — cached (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md
          #   §B.3) since this is a live dashboard read (Dependency
          #   Dashboard, rao-020), not just an internal traversal input.
          def edges_for_project(project_id)
            Rails.cache.fetch(cache_key(project_id)) do
              task_ids = RedminefluxAgentosAiTask.where(project_id: project_id).pluck(:id)
              RedminefluxAgentosDependency.where(ai_task_id: task_ids).to_a
            end
          end

          # Explicit invalidation (docs/PHASE1-SPECIFICATION.md §1.3 NFR) —
          # called by both `add_edge` and `remove_edge`; never time-based.
          def invalidate!(project_id)
            Rails.cache.delete(cache_key(project_id))
          end

          private

          def cache_key(project_id)
            "redmineflux_agentos/dependency_graph/#{project_id}"
          end

          # Depth-first search from `depends_on` along existing edges —
          # if it can reach `ai_task`, the new edge would close a loop.
          def creates_cycle?(ai_task, depends_on)
            return true if ai_task.id == depends_on.id

            visited = {}
            stack = [depends_on.id]

            until stack.empty?
              current = stack.pop
              return true if current == ai_task.id
              next if visited[current]

              visited[current] = true
              stack.concat(RedminefluxAgentosDependency.where(ai_task_id: current).pluck(:depends_on_ai_task_id))
            end

            false
          end
        end
      end
    end
  end
end
