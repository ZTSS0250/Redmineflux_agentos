# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    module DependencyEngine
      # DependencyEngine::Graph — builds/validates the DAG of
      # RedminefluxAgentosDependency edges, with an application-level cycle
      # check at insert time (docs/DATABASE-SCHEMA.md — no DB-level cycle
      # constraint is expressible for a graph).
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

            RedminefluxAgentosDependency.create!(
              ai_task_id: ai_task.id, depends_on_ai_task_id: depends_on.id, dependency_type: 'blocks'
            )
          end

          private

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
