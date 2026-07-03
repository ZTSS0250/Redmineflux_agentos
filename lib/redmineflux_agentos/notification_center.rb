# frozen_string_literal: true

module RedminefluxAgentos
  # Notification Center (WORKFLOW.md §23) — routes AgentOS lifecycle
  # events to Redmine's native (email-based) notification system via
  # `NotificationMailer`. Each public method here is one named row from
  # §23's table; only the rows with a concrete, already-modelable
  # recipient set in the current data model are implemented.
  #
  # Two of §23's six rows are explicitly NOT implemented here — a
  # transparent Gate 1 finding, not a silent omission (same pattern as
  # `ConversationManager::Session` in rao-020):
  #
  # - "Workflow Blocked ... Project Manager Agent (internal)": not a
  #   Redmine-notification concern at all per §23's own "(internal)"
  #   qualifier — `DependencyEngine::Scheduler` already handles the real
  #   behavior (auto-resume on clear). "...optionally the human PM if
  #   SLA at risk" requires SLA tracking that exists nowhere in this
  #   codebase; inventing it here would be new feature design, which is
  #   explicitly out of scope for rao-021's "verification pass, not new
  #   design" (Implementation Notes).
  # - "Project Completed": no ticket through rao-020 ever built
  #   AgentOS-level project-completion detection
  #   (`RedminefluxAgentosProjectPlan::STATUSES` has no `completed`
  #   value; nothing anywhere computes "is this project's AgentOS work
  #   done"). Building that detection now would be new feature work, not
  #   a routing wire-up — logged as a gap for a future ticket.
  module NotificationCenter
    class << self
      # Agent Completed -> ticket assignee/watchers (WORKFLOW.md §23).
      def agent_completed(agent_run)
        issue = agent_run.issue
        return [] unless issue

        recipients = ([issue.assigned_to] + issue.watcher_users).compact.uniq
        deliver(recipients, subject: "[AgentOS] Agent run completed: #{issue.subject}",
                             body: "#{agent_run.agent.name} finished its run on ##{issue.id} #{issue.subject}.")
      end

      # Execution Failed -> project admins / users with `view_agent_logs`
      # (WORKFLOW.md §23). `agent_run.dead` is the terminal
      # retries-exhausted state (WORKFLOW.md §8's `attempts >= max`
      # transition), not the intermediate, still-retryable `failed`
      # state — matching "surfaced ... for human intervention"
      # (docs/PHASE1-SPECIFICATION.md §6.1).
      def agent_dead(agent_run)
        project = agent_run.project
        return [] unless project

        recipients = project.users.select { |u| u.allowed_to?(:view_agent_logs, project) }
        deliver(recipients, subject: "[AgentOS] Agent run failed: #{agent_run.agent.name}",
                             body: "Agent run ##{agent_run.id} (#{agent_run.agent.name}) exhausted its retry " \
                                   "attempts (#{agent_run.attempts}/#{agent_run.max_attempts}) and needs attention.")
      end

      # Approval Needed -> "users holding the permission that gates the
      # specific tool" (WORKFLOW.md §23). There is no per-tool permission
      # registry to resolve anything finer than this — approximated as
      # `run_ai_tasks`, the actual Redmine permission
      # `AgentDashboardsController#approve`/`#reject` (rao-020) requires
      # to act on this exact row. Only resolvable when `mcp_tool_call` has
      # an `agent_run` (rao-021 addition to `Mcp::Executor.call` — see
      # that file) — a human-initiated pending confirmation has no
      # project to resolve recipients against and is silently skipped.
      def approval_needed(mcp_tool_call)
        project = mcp_tool_call.agent_run&.project
        return [] unless project

        recipients = project.users.select { |u| u.allowed_to?(:run_ai_tasks, project) }
        deliver(recipients, subject: "[AgentOS] Approval needed: #{mcp_tool_call.tool_name}",
                             body: "#{mcp_tool_call.tool_name} is waiting for approval in #{project.name}.")
      end

      # Agent Started -> project watchers, default OFF ("optional,
      # likely noisy", WORKFLOW.md §23) — gated by the
      # `notify_on_agent_started` config key (`Configuration::Store`),
      # which §23 requires but never named (same gap rao-019 filled for
      # the concurrency caps). Redmine core has no project-level watcher
      # concept (only Issue/Wiki::Page/etc. are Watchable) — approximated
      # as full project membership (`project.users`, the same association
      # every other method here reads from — kept consistent rather than
      # each method inventing its own way to enumerate "everyone in the
      # project").
      def agent_started(agent_run)
        project = agent_run.project
        return [] unless project
        return [] unless RedminefluxAgentos::Configuration::Store.get('notify_on_agent_started', project: project)

        deliver(project.users, subject: "[AgentOS] Agent run started: #{agent_run.agent.name}",
                                body: "#{agent_run.agent.name} started a run in #{project.name}.")
      end

      private

      def deliver(recipients, subject:, body:)
        recipients.select { |u| u.mail.present? }.each do |user|
          RedminefluxAgentos::NotificationMailer.event_notification(user, subject, body).deliver_later
        end
      end
    end
  end
end
