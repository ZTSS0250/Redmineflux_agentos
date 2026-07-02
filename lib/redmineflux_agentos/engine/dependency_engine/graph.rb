# frozen_string_literal: true

module RedminefluxAgentos
  module Engine
    module DependencyEngine
      # DependencyEngine::Graph — builds/validates the DAG of
      # RedminefluxAgentosDependency edges, with an application-level cycle
      # check at insert time (docs/DATABASE-SCHEMA.md — no DB-level cycle
      # constraint is expressible for a graph). Phase 14 (rao-019)
      # implements the body.
      module Graph
        def self.add_edge(ai_task, depends_on:)
          raise NotImplementedError, 'Dependency edge insertion (with cycle check) is implemented in Phase 14 (rao-019)'
        end
      end
    end
  end
end
