# frozen_string_literal: true

module RedminefluxAgentos
  # Dependency Dashboard (docs/UI-WIREFRAMES.md §4). Data source:
  # `dependencies` + `ai_tasks.status` (docs/PHASE9-UI-UX-SPECIFICATION.md
  # §6) — a graph visualization's exact rendering is explicitly deferred
  # (rao-020 QA Test Plan, "visual polish beyond functional layout");
  # this exposes the underlying edge list a future richer client-side
  # visualization renders from.
  class DependencyDashboardsController < BaseController
    def show
      @edges = RedminefluxAgentos::Engine::DependencyEngine::Graph.edges_for_project(@project.id)
      task_ids = @edges.flat_map { |e| [e.ai_task_id, e.depends_on_ai_task_id] }.uniq
      @tasks_by_id = RedminefluxAgentosAiTask.where(id: task_ids).index_by(&:id)
    end
  end
end
