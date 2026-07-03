# frozen_string_literal: true

module RedminefluxAgentos
  # Sprint Planner — Release Planner's drill-down
  # (docs/PHASE9-UI-UX-SPECIFICATION.md §5/§6). Ticket board + burndown,
  # `ai_tasks` scoped to one `sprint_id` — burndown-over-time charting is
  # explicitly deferred (visual polish, rao-020 QA Test Plan); the ticket
  # board (counts by status) is the functional part implemented here.
  class SprintsController < BaseController
    def show
      @sprint = RedminefluxAgentosSprint.find(params[:id])
      @tasks = RedminefluxAgentosAiTask.where(sprint_id: @sprint.id).order(:priority)
      @counts_by_status = @tasks.group(:status).count
    end
  end
end
