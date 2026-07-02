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
  module SystemUserProvisioner
    LOGIN = 'agentos_system'
    ROLE_NAME = 'AgentOS System'
    ROLE_PERMISSIONS = %i[
      view_agentos_dashboard create_ai_project run_ai_tasks
      view_token_usage view_cost_dashboard view_agent_logs
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
