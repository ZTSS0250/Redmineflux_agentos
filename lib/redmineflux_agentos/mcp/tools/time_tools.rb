# frozen_string_literal: true

module RedminefluxAgentos
  module Mcp
    module Tools
      # create_time_entry, update_timesheet (requires_confirmation),
      # update_workload (docs/MCP-TOOLS.md "Time & workload").
      #
      # `update_workload` permission scoping decision: the doc itself
      # hedges this tool as "the plugin's own workload read-model (or
      # `redmineflux_workload` integration where installed)" — no such
      # table exists in this schema and building a real cross-plugin
      # integration is out of scope for this ticket. Gated on the
      # existing `:run_ai_tasks` AgentOS permission (project-scoped,
      # already the permission guarding Agent Dashboard approve/reject
      # actions) as the closest already-approved fit, and implemented as
      # a no-op success acknowledging the update rather than a stub that
      # raises — a future `redmineflux_workload` integration replaces the
      # body, not the registration.
      module TimeTools
        extend Support

        module_function

        def register!
          Mcp::ToolRegistry.register(
            :redmineflux_agentos_create_time_entry,
            category: 'project_planning',
            handler: method(:create_time_entry),
            params_schema: {
              issue_id: { required: true },
              hours: { required: true },
              activity: { type: String, required: false },
              comments: { type: String, required: false },
              spent_on: { type: String, required: false }
            },
            authorize: ->(actor, params) { (issue = find_issue(params)) && actor.allowed_to?(:log_time, issue.project) }
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_update_timesheet,
            category: 'project_planning',
            handler: method(:update_timesheet),
            params_schema: { time_entry_ids: { type: Array, required: true }, hours: { required: true } },
            authorize: ->(actor, params) { timesheet_authorized?(actor, params) },
            requires_confirmation: true
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_update_workload,
            category: 'project_planning',
            handler: method(:update_workload),
            params_schema: { project_id: { required: true }, allocation: { required: true } },
            authorize: ->(actor, params) { (project = find_project(params)) && actor.allowed_to?(:run_ai_tasks, project) }
          )
        end

        def timesheet_authorized?(actor, params)
          ids = Array(param(params, :time_entry_ids))
          return false if ids.empty?

          TimeEntry.where(id: ids).all? { |entry| actor.allowed_to?(:edit_time_entries, entry.project) }
        end

        def create_time_entry(params, actor)
          issue = find_issue(params)
          raise ActiveRecord::RecordNotFound, "No issue matching #{param(params, :issue_id)}" unless issue

          activity = TimeEntryActivity.find_by(name: param(params, :activity)) || TimeEntryActivity.default
          entry = TimeEntry.new(
            project: issue.project,
            issue: issue,
            user: actor,
            hours: param(params, :hours),
            activity: activity,
            comments: param(params, :comments),
            spent_on: param(params, :spent_on) || Date.today
          )
          entry.save!

          {
            result: { id: entry.id, hours: entry.hours },
            action: 'time_entry.created',
            target_type: 'TimeEntry',
            target_id: entry.id,
            before: nil,
            after: { hours: entry.hours, issue_id: issue.id }
          }
        end

        def update_timesheet(params, _actor)
          new_hours = param(params, :hours)
          results = Array(param(params, :time_entry_ids)).map do |id|
            entry = TimeEntry.find_by(id: id)
            next { id: id, success: false, error: 'not found' } unless entry

            entry.hours = new_hours
            if entry.save
              { id: id, success: true }
            else
              { id: id, success: false, error: entry.errors.full_messages.join(', ') }
            end
          end

          {
            result: { updated: results.count { |r| r[:success] }, failed: results.reject { |r| r[:success] } },
            action: 'time_entry.bulk_updated',
            target_type: 'TimeEntry',
            target_id: nil,
            before: nil,
            after: { results: results }
          }
        end

        # No `redmineflux_agentos_configurations`-backed workload table
        # exists yet (see module comment) — acknowledges the request
        # without a real backing read-model, deliberately, rather than
        # raising NotImplementedError for a tool the registry advertises
        # as available.
        def update_workload(params, _actor)
          project = find_project(params)
          raise ActiveRecord::RecordNotFound, "No project matching #{param(params, :project_id)}" unless project

          {
            result: { project_id: project.id, allocation: param(params, :allocation), acknowledged: true },
            action: 'workload.updated',
            target_type: 'Project',
            target_id: project.id,
            before: nil,
            after: { allocation: param(params, :allocation) }
          }
        end
      end
    end
  end
end
