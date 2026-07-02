# frozen_string_literal: true

module RedminefluxAgentos
  # Agent Dashboard (index) + Agent Monitoring drill-down (show) —
  # docs/PHASE9-UI-UX-SPECIFICATION.md §5. approve/reject act on the
  # Pending Approvals queue (WORKFLOW.md §22) and are gated by
  # :run_ai_tasks, not :view_agentos_dashboard (init.rb permission map).
  class AgentDashboardsController < BaseController
    def index
    end

    def show
    end

    def approve
      head :no_content
    end

    def reject
      head :no_content
    end
  end
end
