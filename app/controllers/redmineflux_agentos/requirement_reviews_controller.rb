# frozen_string_literal: true

module RedminefluxAgentos
  # SRS approval screen (docs/UI-WIREFRAMES.md §2).
  #
  # Same documented gap as `ChatController` (rao-020 Gate 1 revision):
  # approving the SRS should trigger the Project Manager Agent's planning
  # turn (WORKFLOW.md §5), which needs `ConversationManager::Session` —
  # not built yet, not this ticket's job. `update` correctly persists the
  # approval decision on `project_plans`; it does not yet kick off planning.
  class RequirementReviewsController < BaseController
    def show
      @project_plan = latest_plan
    end

    def update
      plan = latest_plan
      raise ActiveRecord::RecordNotFound, 'No SRS draft to review for this project' unless plan

      if params[:approve] == '1'
        plan.update!(status: 'approved', approved_by_id: User.current.id, approved_at: Time.now)
      else
        plan.update!(status: 'draft')
      end

      redirect_to agentos_requirement_review_path(project_id: @project.id)
    end

    private

    def latest_plan
      RedminefluxAgentosProjectPlan.where(project_id: @project.id).order(version: :desc).first
    end
  end
end
