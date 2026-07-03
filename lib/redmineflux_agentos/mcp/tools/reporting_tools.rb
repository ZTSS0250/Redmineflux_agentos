# frozen_string_literal: true

module RedminefluxAgentos
  module Mcp
    module Tools
      # generate_report (docs/MCP-TOOLS.md "Reporting") — read-only.
      # Gated on the existing `:view_agentos_dashboard` permission (an
      # AgentOS-level concern, not a raw Redmine data read like the other
      # categories) since a report summarizes AgentOS's own `ai_tasks`,
      # not Redmine issues directly.
      module ReportingTools
        extend Support

        module_function

        def register!
          Mcp::ToolRegistry.register(
            :redmineflux_agentos_generate_report,
            category: 'reporting',
            handler: method(:generate_report),
            params_schema: { project_id: { required: true }, report_type: { type: String, required: false } },
            authorize: ->(actor, params) { (project = find_project(params)) && actor.allowed_to?(:view_agentos_dashboard, project) },
            read_only: true
          )
        end

        def generate_report(params, _actor)
          project = find_project(params)
          raise ActiveRecord::RecordNotFound, "No project matching #{param(params, :project_id)}" unless project

          tasks = RedminefluxAgentosAiTask.where(project_id: project.id)
          by_status = tasks.group(:status).count

          {
            result: {
              project_id: project.id,
              report_type: param(params, :report_type) || 'progress',
              total_tasks: tasks.count,
              by_status: by_status
            }
          }
        end
      end
    end
  end
end
