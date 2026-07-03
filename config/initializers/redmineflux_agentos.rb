# frozen_string_literal: true

# ---------------------------------------------------------------------------
# redmineflux_agentos boot-time registration (docs/PHASE5-FOLDER-STRUCTURE.md
# §9). Wrapped in `to_prepare` so it re-runs correctly under both eager
# (production) and lazy (development) class loading — required per rao-009
# Gate 3 finding #2 / rao-010 Gate 2 finding #1.
# ---------------------------------------------------------------------------

Rails.application.config.to_prepare do
  # --- Provider registration (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §3.1) ---
  RedminefluxAgentos::Providers::Registry.register(:mock, RedminefluxAgentos::Providers::Mock::MockProvider)

  # A misconfigured fixture_directory must be a loud boot-time warning,
  # never a silent per-request failure (rao-008 Gate 3 finding #1,
  # rao-017 Test Case #4).
  RedminefluxAgentos::Providers::Mock::FixtureLoader.validate_directory!

  # --- Agent registration (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.5) ---
  # All 17 roles register, including the reserved Code Review Agent —
  # AgentEngine::Registry itself refuses to *schedule* it (rao-011 Gate 3
  # finding #1), so registering its class here is safe.
  [
    RedminefluxAgentos::Agents::ProjectManagerAgent,
    RedminefluxAgentos::Agents::RequirementAnalystAgent,
    RedminefluxAgentos::Agents::BusinessAnalystAgent,
    RedminefluxAgentos::Agents::ScrumMasterAgent,
    RedminefluxAgentos::Agents::SolutionArchitectAgent,
    RedminefluxAgentos::Agents::DatabaseAgent,
    RedminefluxAgentos::Agents::BackendAgent,
    RedminefluxAgentos::Agents::ApiAgent,
    RedminefluxAgentos::Agents::FrontendAgent,
    RedminefluxAgentos::Agents::UiUxAgent,
    RedminefluxAgentos::Agents::QaAgent,
    RedminefluxAgentos::Agents::SecurityAgent,
    RedminefluxAgentos::Agents::DevopsAgent,
    RedminefluxAgentos::Agents::DeploymentAgent,
    RedminefluxAgentos::Agents::CodeReviewAgent,
    RedminefluxAgentos::Agents::DocumentationAgent,
    RedminefluxAgentos::Agents::ReportingAgent
  ].each { |agent_class| RedminefluxAgentos::Engine::AgentEngine::Registry.register(agent_class) }

  # --- MCP tool registration (docs/PHASE7-MCP-ARCHITECTURE.md §2) ---
  # `ToolRegistry.register` raises at boot if any entry is missing a
  # `params_schema` (rao-012 Gate 3 finding #1) — a tool file with a typo'd
  # or omitted schema fails plugin boot, not a silent per-request gap.
  [
    RedminefluxAgentos::Mcp::Tools::ProjectTools,
    RedminefluxAgentos::Mcp::Tools::IssueTools,
    RedminefluxAgentos::Mcp::Tools::WikiTools,
    RedminefluxAgentos::Mcp::Tools::FileTools,
    RedminefluxAgentos::Mcp::Tools::TimeTools,
    RedminefluxAgentos::Mcp::Tools::ReportingTools
  ].each(&:register!)

  # --- Redmine-core association extension (docs/PHASE4-DATABASE-DESIGN.md §10) ---
  # Standard Redmine plugin practice — a runtime association addition, not a
  # core-file edit. One-directional: destroying a Project/Issue cleans up
  # AgentOS's own rows; it never reaches back to affect a different
  # Redmine record (rao-009 Gate 2 finding #3).
  Project.class_eval do
    has_many :redmineflux_agentos_ai_tasks, class_name: 'RedminefluxAgentosAiTask', dependent: :destroy
    has_many :redmineflux_agentos_conversations, class_name: 'RedminefluxAgentosConversation', dependent: :destroy
    has_many :redmineflux_agentos_project_plans, class_name: 'RedminefluxAgentosProjectPlan', dependent: :destroy
    has_many :redmineflux_agentos_agent_runs, class_name: 'RedminefluxAgentosAgentRun', dependent: :destroy
  end

  Issue.class_eval do
    has_one :redmineflux_agentos_ai_task, class_name: 'RedminefluxAgentosAiTask', foreign_key: 'issue_id'

    # A Redmine-native issue deletion (bypassing the delete_issue MCP tool
    # entirely, e.g. via the core admin UI) still needs the ai_tasks row
    # marked `deleted`, not silently orphaned or destroyed
    # (docs/PHASE4-DATABASE-DESIGN.md §10's Soft Delete Strategy — the
    # ai_task row itself is retained for historical/dependency-graph
    # purposes). The delete_issue MCP tool's own handler (Phase 13,
    # rao-018) performs the same update directly when *it* is the
    # deletion path; this callback is the safety net for every other path.
    before_destroy do
      redmineflux_agentos_ai_task&.update(status: 'deleted', issue_id: nil)
    end
  end

  # --- Event Bus subscribers (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.7) ---
  # Subscriber is deliberately thin/fast (rao-007 Gate 2 finding #1 —
  # subscribers must be non-blocking, since ActiveSupport::Notifications
  # dispatches synchronously in-process): a status-name check plus a
  # bounded DB query for already-`waiting_on_dep` runs, not an unbounded
  # or slow operation. `on_issue_closed` fires only when the new status is
  # actually closed (`IssueStatus#is_closed?`) — not on every field
  # change `update_issue`/`bulk_close_issues` (rao-018) might publish this
  # event for.
  RedminefluxAgentos::Engine::EventBus.subscribe('issue.status_changed') do |*, payload|
    issue = payload[:record]
    RedminefluxAgentos::Engine::DependencyEngine::Scheduler.on_issue_closed(issue) if issue&.status&.is_closed?
  end

  # rao-021 (Phase 16) — NotificationCenter (WORKFLOW.md §23). Each
  # handler only resolves a recipient list and enqueues mail delivery
  # (`.deliver_later`), matching this subscriber block's own
  # fast/non-blocking requirement (comment above).
  RedminefluxAgentos::Engine::EventBus.subscribe('agent_run.running') do |*, payload|
    RedminefluxAgentos::NotificationCenter.agent_started(payload[:record])
  end

  RedminefluxAgentos::Engine::EventBus.subscribe('agent_run.completed') do |*, payload|
    RedminefluxAgentos::NotificationCenter.agent_completed(payload[:record])
  end

  RedminefluxAgentos::Engine::EventBus.subscribe('agent_run.dead') do |*, payload|
    RedminefluxAgentos::NotificationCenter.agent_dead(payload[:record])
  end

  RedminefluxAgentos::Engine::EventBus.subscribe('mcp_tool_call.pending_confirmation') do |*, payload|
    RedminefluxAgentos::NotificationCenter.approval_needed(payload[:record])
  end
end
