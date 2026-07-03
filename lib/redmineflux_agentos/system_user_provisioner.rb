# frozen_string_literal: true

module RedminefluxAgentos
  # Provisions and maintains the AgentOS System user (rao-015,
  # docs/PHASE7-MCP-ARCHITECTURE.md §3) — the User.current identity for
  # every autonomous, non-human-triggered agent action (a scheduled tick,
  # a passive ticket-close reaction). Non-admin, cannot log in
  # interactively, added as a Member with a Role scoped to exactly the
  # AgentOS project_module permission set — never core Redmine
  # permissions, per rao-015 Gate 2 finding #2.
  #
  # Idempotent by design (rao-015 Gate 3 finding #2): safe to call
  # repeatedly, including for a project whose :agentos module was
  # disabled and re-enabled, or restored from a backup — there is no
  # Redmine core "module enabled" event to hook a one-time creation into,
  # so `ensure_membership!` must be called at every point membership might
  # be needed (module enablement UI, and lazily before any agent-initiated
  # MCP call), not just once at boot.
  #
  # NOTE: `status: User::STATUS_LOCKED` prevents interactive login (the
  # Account controller checks this on sign-in) without, as far as
  # Redmine's Principal#allowed_to? implementation goes, affecting
  # programmatic permission checks when this user is set as User.current
  # for a background job. This has not been verified against a running
  # Redmine instance — flagged explicitly per rao-015's own caveat that
  # this ticket cannot move to `done` until tested live.
  #
  # Gap fixed during rao-019 (Phase 14) implementation: the original
  # ROLE_PERMISSIONS list only granted AgentOS's own UI-level permissions
  # (dashboard/token/cost viewing) — none of the actual Redmine **core**
  # permissions (`:add_issues`, `:edit_project`, etc.) that
  # `Mcp::Executor`'s Layer 1 checks (rao-018) require. As originally
  # provisioned, the System user could never have passed Layer 1 for any
  # of the 20 MCP tools an agent-initiated call needs — every
  # agent-initiated write would have failed permission checks on a live
  # instance despite Layer 2 (tool_allowlist) correctly allowing it. Fixed
  # by adding exactly the core permissions the six tool files' `authorize:`
  # procs check, least-privilege (no `:delete_issues`-adjacent admin
  # permissions beyond what a tool actually gates on).
  module SystemUserProvisioner
    LOGIN = 'agentos_system'
    ROLE_NAME = 'AgentOS System'
    ROLE_PERMISSIONS = %i[
      view_agentos_dashboard create_ai_project run_ai_tasks
      view_token_usage view_cost_dashboard view_agent_logs
      add_project edit_project manage_versions
      add_issues edit_issues add_issue_notes manage_issue_relations delete_issues view_issues
      edit_wiki_pages view_wiki_pages
      manage_files
      log_time edit_time_entries
    ].freeze

    class << self
      def user
        User.find_by(login: LOGIN) || create_user!
      end

      def role
        Role.find_by(name: ROLE_NAME) || create_role!
      end

      def ensure_membership!(project)
        return if Member.exists?(project_id: project.id, user_id: user.id)

        Member.create!(project: project, user: user, roles: [role])
      end

      private

      def create_user!
        User.create!(
          login: LOGIN,
          firstname: 'AgentOS',
          lastname: 'System',
          mail: "#{LOGIN}@example.invalid",
          status: User::STATUS_LOCKED,
          admin: false
        )
      end

      def create_role!
        Role.create!(name: ROLE_NAME, permissions: ROLE_PERMISSIONS)
      end
    end
  end
end
