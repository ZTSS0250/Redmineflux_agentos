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

  # --- Event Bus subscribers: intentionally NOT wired up yet ---
  # DependencyEngine::Scheduler.on_issue_closed is currently a stub that
  # raises NotImplementedError (Phase 14, rao-019). Subscribing it now
  # would crash on the first real issue-status-change event instead of
  # degrading gracefully — uncomment once Phase 14 implements the handler:
  #
  # RedminefluxAgentos::Engine::EventBus.subscribe('issue_status_changed') do |*, payload|
  #   RedminefluxAgentos::Engine::DependencyEngine::Scheduler.on_issue_closed(payload[:issue])
  # end
end
