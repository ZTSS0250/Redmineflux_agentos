# frozen_string_literal: true

module RedminefluxAgentos
  # Agent Dashboard (index) + Agent Monitoring drill-down (show) —
  # docs/PHASE9-UI-UX-SPECIFICATION.md §5/§6. approve/reject act on the
  # Pending Approvals queue (WORKFLOW.md §22) and are gated by
  # :run_ai_tasks, not :view_agentos_dashboard (init.rb permission map).
  #
  # `approve`/`reject`'s target: the `agent_dashboards` resource's own
  # `:id` (Phase 10 routing) semantically means "which agent" for `show`,
  # not "which pending mcp_tool_call" — rather than restructure the
  # already-shipped route tree, these two actions accept an explicit
  # `mcp_tool_call_id` param (sent by the Pending Approvals form/JS),
  # falling back to `:id` for a caller that reasonably assumes the URL's
  # own id already identifies the call being approved/rejected.
  class AgentDashboardsController < BaseController
    # Status table + Pending Approvals panel
    # (docs/PHASE9-UI-UX-SPECIFICATION.md §6) — both read directly from
    # their denormalized source, never a live join through `agent_runs`
    # beyond the one already-indexed `(project_id, status)`/`(status)`
    # lookup (Phase 2 §B.9).
    def index
      @agent_runs = RedminefluxAgentosAgentRun.where(project_id: @project.id).order(created_at: :desc).limit(100)
      run_ids = RedminefluxAgentosAgentRun.where(project_id: @project.id).pluck(:id)
      @pending_approvals = RedminefluxAgentosMcpToolCall.where(status: 'pending_confirmation', agent_run_id: run_ids)
                                                         .order(created_at: :asc)
    end

    # Agent Monitoring drill-down: run history, memory contents, recent
    # tool calls — all scoped to one `agent_id` (§6).
    def show
      @agent = RedminefluxAgentosAgent.find(params[:id])
      @agent_runs = RedminefluxAgentosAgentRun.where(project_id: @project.id, agent_id: @agent.id)
                                               .order(created_at: :desc)
      @memories = RedminefluxAgentosAgentMemory.where(agent_id: @agent.id, project_id: @project.id)
      @recent_tool_calls = RedminefluxAgentosMcpToolCall.where(agent_run_id: @agent_runs.pluck(:id))
                                                         .order(created_at: :desc).limit(50)
    end

    def approve
      @call = RedminefluxAgentosMcpToolCall.find(params[:mcp_tool_call_id] || params[:id])
      RedminefluxAgentos::Mcp::Executor.confirm(@call.id, confirmed_by: User.current)
      respond_to do |format|
        format.js
        format.html { redirect_to agentos_agent_dashboards_path(project_id: @project.id) }
      end
    end

    def reject
      @call = RedminefluxAgentosMcpToolCall.find(params[:mcp_tool_call_id] || params[:id])
      RedminefluxAgentos::Mcp::Executor.reject(@call.id, confirmed_by: User.current)
      respond_to do |format|
        format.js
        format.html { redirect_to agentos_agent_dashboards_path(project_id: @project.id) }
      end
    end
  end
end
