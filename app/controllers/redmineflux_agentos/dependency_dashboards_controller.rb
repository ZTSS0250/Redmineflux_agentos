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
      task_ids = RedminefluxAgentosAiTask.where(project_id: @project.id).pluck(:id)
      @edges = RedminefluxAgentosDependency.where(ai_task_id: task_ids)
      @tasks_by_id = RedminefluxAgentosAiTask.where(id: task_ids).index_by(&:id)
    end
  end
end
