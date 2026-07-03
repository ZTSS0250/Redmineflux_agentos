# frozen_string_literal: true

module RedminefluxAgentos
  # Release Planner (docs/UI-WIREFRAMES.md §5). Data source: `releases`,
  # `sprints`, `ai_tasks` (docs/PHASE9-UI-UX-SPECIFICATION.md §6).
  class ReleasesController < BaseController
    def index
      @releases = RedminefluxAgentosRelease.joins(:project_plan)
                                            .where(redmineflux_agentos_project_plans: { project_id: @project.id })
                                            .order(:sequence)
    end

    def show
      @release = RedminefluxAgentosRelease.find(params[:id])
      @sprints = RedminefluxAgentosSprint.where(release_id: @release.id).order(:start_date)
      sprint_ids = @sprints.pluck(:id)
      @ticket_counts_by_sprint = RedminefluxAgentosAiTask.where(sprint_id: sprint_ids).group(:sprint_id).count
    end
  end
end
