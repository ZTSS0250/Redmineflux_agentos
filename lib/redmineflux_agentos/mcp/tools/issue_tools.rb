# frozen_string_literal: true

module RedminefluxAgentos
  module Mcp
    module Tools
      # create_issue, update_issue, assign_issue, add_comment,
      # create_issue_relation, bulk_close_issues (requires_confirmation),
      # delete_issue (requires_confirmation), search_issues, read_ticket,
      # read_comments (docs/MCP-TOOLS.md "Issues").
      #
      # `bulk_close_issues` decision (Gate 3 finding #1 — this ticket
      # requires picking one deliberately, not leaving it undefined):
      # **per-item reporting, not an all-or-nothing transaction**. A batch
      # spans issues that may belong to different projects/workflows;
      # wrapping them in one transaction would mean one issue's workflow
      # validation failure silently undoes N-1 otherwise-valid closures,
      # which is more surprising than a partial result, not less.
      # `result_json` reports success/failure per issue id instead.
      module IssueTools
        extend Support

        module_function

        def register!
          Mcp::ToolRegistry.register(
            :redmineflux_agentos_create_issue,
            category: 'ticket_generation',
            handler: method(:create_issue),
            params_schema: {
              project_id: { required: true },
              tracker: { type: String, required: true },
              subject: { type: String, required: true },
              description: { type: String, required: false },
              priority: { type: String, required: false }
            },
            authorize: ->(actor, params) { (project = find_project(params)) && actor.allowed_to?(:add_issues, project) }
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_update_issue,
            category: 'ticket_generation',
            handler: method(:update_issue),
            params_schema: {
              issue_id: { required: true },
              subject: { type: String, required: false },
              description: { type: String, required: false },
              status: { type: String, required: false },
              priority: { type: String, required: false }
            },
            authorize: ->(actor, params) { (issue = find_issue(params)) && actor.allowed_to?(:edit_issues, issue.project) }
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_assign_issue,
            category: 'project_planning',
            handler: method(:assign_issue),
            params_schema: { issue_id: { required: true }, assignee_id: { required: true } },
            authorize: ->(actor, params) { (issue = find_issue(params)) && actor.allowed_to?(:edit_issues, issue.project) }
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_add_comment,
            category: 'reporting',
            handler: method(:add_comment),
            params_schema: { issue_id: { required: true }, notes: { type: String, required: true } },
            authorize: ->(actor, params) { (issue = find_issue(params)) && actor.allowed_to?(:add_issue_notes, issue.project) }
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_create_issue_relation,
            category: 'dependency_analysis',
            handler: method(:create_issue_relation),
            params_schema: {
              issue_id: { required: true },
              related_issue_id: { required: true },
              relation_type: { type: String, required: false }
            },
            authorize: ->(actor, params) { (issue = find_issue(params)) && actor.allowed_to?(:manage_issue_relations, issue.project) }
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_bulk_close_issues,
            category: 'ticket_generation',
            handler: method(:bulk_close_issues),
            params_schema: { issue_ids: { type: Array, required: true }, status: { type: String, required: false } },
            authorize: ->(actor, params) { bulk_close_authorized?(actor, params) },
            requires_confirmation: true
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_delete_issue,
            category: 'ticket_generation',
            handler: method(:delete_issue),
            params_schema: { issue_id: { required: true } },
            authorize: ->(actor, params) { (issue = find_issue(params)) && actor.allowed_to?(:delete_issues, issue.project) },
            requires_confirmation: true
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_search_issues,
            category: 'ticket_generation',
            handler: method(:search_issues),
            params_schema: {
              project_id: { required: false },
              status: { type: String, required: false },
              assigned_to_id: { required: false },
              limit: { required: false }
            },
            # Visibility is enforced by the `Issue.visible(actor)` scope
            # the handler queries against, not a separate binary gate —
            # there is no "denied" outcome for a search, only fewer
            # visible results.
            authorize: ->(_actor, _params) { true },
            read_only: true
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_read_ticket,
            category: 'ticket_generation',
            handler: method(:read_ticket),
            params_schema: { issue_id: { required: true } },
            authorize: ->(actor, params) { (issue = find_issue(params)) && issue.visible?(actor) },
            read_only: true
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_read_comments,
            category: 'ticket_generation',
            handler: method(:read_comments),
            params_schema: { issue_id: { required: true } },
            authorize: ->(actor, params) { (issue = find_issue(params)) && issue.visible?(actor) },
            read_only: true
          )
        end

        def bulk_close_authorized?(actor, params)
          ids = Array(param(params, :issue_ids))
          return false if ids.empty?

          Issue.where(id: ids).all? { |issue| actor.allowed_to?(:edit_issues, issue.project) }
        end

        def create_issue(params, actor)
          project = find_project(params)
          raise ActiveRecord::RecordNotFound, "No project matching #{param(params, :project_id)}" unless project

          tracker = Tracker.find_by(name: param(params, :tracker)) || project.trackers.first
          priority = IssuePriority.find_by(name: param(params, :priority)) || IssuePriority.default || IssuePriority.active.first

          issue = Issue.new(
            project: project,
            tracker: tracker,
            subject: param(params, :subject),
            description: param(params, :description),
            author: actor,
            priority: priority,
            status: tracker&.default_status || IssueStatus.sorted.first
          )
          issue.save!

          {
            result: { id: issue.id, subject: issue.subject, project_id: issue.project_id },
            action: 'issue.created',
            target_type: 'Issue',
            target_id: issue.id,
            before: nil,
            after: { subject: issue.subject, tracker: tracker&.name }
          }
        end

        def update_issue(params, _actor)
          issue = find_issue(params)
          raise ActiveRecord::RecordNotFound, "No issue matching #{param(params, :issue_id)}" unless issue

          before = issue.attributes.slice('subject', 'description', 'status_id', 'priority_id')

          issue.subject = param(params, :subject) if param(params, :subject)
          issue.description = param(params, :description) if param(params, :description)
          if (status_name = param(params, :status))
            issue.status = IssueStatus.find_by(name: status_name) || issue.status
          end
          if (priority_name = param(params, :priority))
            issue.priority = IssuePriority.find_by(name: priority_name) || issue.priority
          end
          issue.save!

          # Fixed during rao-019 (Phase 14) implementation: this handler
          # changed `issue.status` directly and never published anything
          # — the Dependency Engine's whole auto-resume mechanism
          # (WORKFLOW.md §13, rao-019) subscribes to `issue.status_changed`
          # to find and re-queue blocked agent_runs, so without this the
          # feature this ticket exists to build would never actually fire
          # through the one real code path that changes issue status.
          if before['status_id'] != issue.status_id
            RedminefluxAgentos::Engine::EventBus.publish('issue.status_changed', record: issue,
                                                                                  from: before['status_id'],
                                                                                  to: issue.status.name)
          end

          {
            result: { id: issue.id, subject: issue.subject, status: issue.status.name },
            action: 'issue.updated',
            target_type: 'Issue',
            target_id: issue.id,
            before: before,
            after: issue.attributes.slice('subject', 'description', 'status_id', 'priority_id')
          }
        end

        def assign_issue(params, _actor)
          issue = find_issue(params)
          raise ActiveRecord::RecordNotFound, "No issue matching #{param(params, :issue_id)}" unless issue

          before = { assigned_to_id: issue.assigned_to_id }
          issue.assigned_to_id = param(params, :assignee_id)
          issue.save!

          {
            result: { id: issue.id, assigned_to_id: issue.assigned_to_id },
            action: 'issue.assigned',
            target_type: 'Issue',
            target_id: issue.id,
            before: before,
            after: { assigned_to_id: issue.assigned_to_id }
          }
        end

        def add_comment(params, actor)
          issue = find_issue(params)
          raise ActiveRecord::RecordNotFound, "No issue matching #{param(params, :issue_id)}" unless issue

          issue.init_journal(actor, param(params, :notes))
          issue.save!

          {
            result: { id: issue.id, journal_id: issue.current_journal&.id },
            action: 'issue.commented',
            target_type: 'Issue',
            target_id: issue.id,
            before: nil,
            after: { notes: param(params, :notes) }
          }
        end

        def create_issue_relation(params, _actor)
          issue = find_issue(params)
          raise ActiveRecord::RecordNotFound, "No issue matching #{param(params, :issue_id)}" unless issue

          related = Issue.find_by(id: param(params, :related_issue_id))
          raise ActiveRecord::RecordNotFound, "No issue matching #{param(params, :related_issue_id)}" unless related

          relation = IssueRelation.create!(
            issue_from: issue,
            issue_to: related,
            relation_type: param(params, :relation_type) || IssueRelation::TYPE_RELATES
          )

          {
            result: { id: relation.id, relation_type: relation.relation_type },
            action: 'issue_relation.created',
            target_type: 'IssueRelation',
            target_id: relation.id,
            before: nil,
            after: { issue_from_id: issue.id, issue_to_id: related.id, relation_type: relation.relation_type }
          }
        end

        def bulk_close_issues(params, _actor)
          closed_status = IssueStatus.find_by(name: param(params, :status)) ||
                          IssueStatus.where(is_closed: true).first

          results = Array(param(params, :issue_ids)).map do |id|
            issue = Issue.find_by(id: id)
            next { id: id, success: false, error: 'not found' } unless issue

            previous_status_id = issue.status_id
            issue.status = closed_status
            if issue.save
              # Same fix as update_issue, above — bulk_close_issues is a
              # second real code path that changes issue status and must
              # publish the same event for the Dependency Engine to react.
              if previous_status_id != issue.status_id
                RedminefluxAgentos::Engine::EventBus.publish('issue.status_changed', record: issue,
                                                                                      from: previous_status_id,
                                                                                      to: issue.status.name)
              end
              { id: id, success: true }
            else
              { id: id, success: false, error: issue.errors.full_messages.join(', ') }
            end
          end

          {
            result: { closed: results.count { |r| r[:success] }, failed: results.reject { |r| r[:success] } },
            action: 'issue.bulk_closed',
            target_type: 'Issue',
            target_id: nil,
            before: nil,
            after: { results: results }
          }
        end

        def delete_issue(params, _actor)
          issue = find_issue(params)
          raise ActiveRecord::RecordNotFound, "No issue matching #{param(params, :issue_id)}" unless issue

          before = { id: issue.id, subject: issue.subject }
          issue_id = issue.id
          # The linked ai_task's status is marked `deleted` by the
          # `Issue#before_destroy` callback already wired in rao-015's
          # initializer (docs/PHASE4-DATABASE-DESIGN.md §10) — it fires
          # for every Issue#destroy regardless of which caller triggered
          # it, so this handler doesn't duplicate that update itself.
          issue.destroy!

          {
            result: { id: issue_id, deleted: true },
            action: 'issue.deleted',
            target_type: 'Issue',
            target_id: issue_id,
            before: before,
            after: nil
          }
        end

        def search_issues(params, actor)
          scope = Issue.visible(actor)
          scope = scope.where(project_id: find_project(params)&.id) if param(params, :project_id)
          if (status_name = param(params, :status))
            scope = scope.joins(:status).where(issue_statuses: { name: status_name })
          end
          scope = scope.where(assigned_to_id: param(params, :assigned_to_id)) if param(params, :assigned_to_id)

          issues = scope.limit(param(params, :limit) || 25)

          { result: { issues: issues.map { |i| { id: i.id, subject: i.subject, status: i.status.name } } } }
        end

        def read_ticket(params, _actor)
          issue = find_issue(params)
          raise ActiveRecord::RecordNotFound, "No issue matching #{param(params, :issue_id)}" unless issue

          {
            result: {
              id: issue.id, subject: issue.subject, description: issue.description,
              status: issue.status.name, priority: issue.priority.name,
              assigned_to_id: issue.assigned_to_id, project_id: issue.project_id
            }
          }
        end

        def read_comments(params, _actor)
          issue = find_issue(params)
          raise ActiveRecord::RecordNotFound, "No issue matching #{param(params, :issue_id)}" unless issue

          # Simplification: does not distinguish private notes
          # (`:view_private_notes`) from public ones — every non-blank
          # note is returned. Documented as a scoping decision, not an
          # oversight.
          notes = issue.journals.select { |j| j.notes.present? }
                       .map { |j| { id: j.id, user_id: j.user_id, notes: j.notes, created_on: j.created_on } }

          { result: { comments: notes } }
        end
      end
    end
  end
end
