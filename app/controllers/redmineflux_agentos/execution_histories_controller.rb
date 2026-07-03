# frozen_string_literal: true

module RedminefluxAgentos
  # Execution History / Logs (docs/UI-WIREFRAMES.md §7) — a filterable
  # event feed over `execution_logs`, `mcp_tool_calls`, `agent_runs`
  # (docs/PHASE9-UI-UX-SPECIFICATION.md §6). Filtering kept simple
  # (`level`/`status` query params) rather than a full query builder,
  # matching this ticket's explicit "functional layout, not visual
  # polish" scope.
  class ExecutionHistoriesController < BaseController
    def show
      run_ids = RedminefluxAgentosAgentRun.where(project_id: @project.id).pluck(:id)

      logs = RedminefluxAgentosExecutionLog.where(agent_run_id: run_ids)
      logs = logs.where(level: params[:level]) if params[:level].present?
      @execution_logs = logs.order(created_at: :desc).limit(200)

      calls = RedminefluxAgentosMcpToolCall.where(agent_run_id: run_ids)
      calls = calls.where(status: params[:status]) if params[:status].present?
      @mcp_tool_calls = calls.order(created_at: :desc).limit(200)
    end
  end
end
