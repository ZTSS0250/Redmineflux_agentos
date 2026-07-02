# frozen_string_literal: true

require 'redmine'

# Expose lib/redmineflux_agentos/** (agents, services, providers, mcp,
# engine, prompts, hooks — docs/PHASE5-FOLDER-STRUCTURE.md §3-§7) to Rails
# autoloading. Standard Redmine plugin pattern — Redmine core does not
# auto-include a plugin's lib/ directory by default.
lib_path = File.expand_path('lib', __dir__)
Rails.application.config.autoload_paths << lib_path
Rails.application.config.eager_load_paths << lib_path

Redmine::Plugin.register :redmineflux_agentos do
  name 'RedmineFlux AgentOS'
  author 'Zehntech Technologies Inc.'
  description 'The AI Operating System for Redmine and RedmineFlux — a multi-agent system that turns a natural-language product idea into a fully planned, ticketed, and continuously-executed Redmine project.'
  version '0.0.1'
  url 'https://github.com/ZTSS0250/Redmineflux_agentos'
  author_url 'https://www.zehntech.com'

  requires_redmine version_or_higher: '5.0.0'

  project_module :agentos do
    permission :view_agentos_dashboard,
               { 'redmineflux_agentos/agent_dashboards' => %i[index show],
                 'redmineflux_agentos/dependency_dashboards' => %i[show] },
               read: true

    permission :create_ai_project,
               { 'redmineflux_agentos/chat' => %i[show create],
                 'redmineflux_agentos/requirement_reviews' => %i[show update] }
    # `new_ai_projects` is intentionally NOT declared inside this
    # project_module block — there is no project yet at that point, so it
    # cannot be gated by a per-project permission check. It is instead
    # checked directly against the global permission in the controller
    # (User.current.allowed_to?(:create_ai_project, nil, global: true)),
    # the same way the "+ New AI Project" menu item's visibility is gated.

    permission :run_ai_tasks,
               { 'redmineflux_agentos/releases' => %i[index show],
                 'redmineflux_agentos/sprints' => %i[show],
                 'redmineflux_agentos/agent_dashboards' => %i[approve reject] }

    permission :view_token_usage,
               { 'redmineflux_agentos/token_usages' => %i[show] },
               read: true

    permission :view_cost_dashboard,
               { 'redmineflux_agentos/cost_dashboards' => %i[show] },
               read: true

    permission :view_agent_logs,
               { 'redmineflux_agentos/execution_histories' => %i[show] },
               read: true
  end

  # Administration-scope permissions — also registered globally so the
  # Administration > AgentOS menu (below) can gate on them independently
  # of any single project's module state (docs/PHASE1-SPECIFICATION.md §5).
  permission :manage_agentos, {}, require: :admin
  permission :manage_ai_agents,
             { 'redmineflux_agentos/admin/agents' => %i[index edit update] },
             require: :admin
  permission :manage_mcp_tools,
             { 'redmineflux_agentos/admin/mcp_tools' => %i[index update] },
             require: :admin
  permission :manage_prompt_templates,
             { 'redmineflux_agentos/admin/prompt_templates' => %i[index show edit update] },
             require: :admin
  permission :manage_ai_configuration,
             { 'redmineflux_agentos/admin/settings' => %i[show update] },
             require: :admin

  # --- Project-level menu (docs/PHASE1-SPECIFICATION.md §4.1) ---
  menu :project_menu, :agentos,
       { controller: 'redmineflux_agentos/agent_dashboards', action: 'index' },
       caption: :label_agentos_dashboard,
       param: :project_id,
       if: proc { |project| project.module_enabled?(:agentos) }

  menu :project_menu, :agentos_chat,
       { controller: 'redmineflux_agentos/chat', action: 'show' },
       caption: :label_agentos_chat, parent: :agentos, param: :project_id

  menu :project_menu, :agentos_requirement_review,
       { controller: 'redmineflux_agentos/requirement_reviews', action: 'show' },
       caption: :label_agentos_requirement_review, parent: :agentos, param: :project_id

  menu :project_menu, :agentos_release_planner,
       { controller: 'redmineflux_agentos/releases', action: 'index' },
       caption: :label_agentos_release_planner, parent: :agentos, param: :project_id

  menu :project_menu, :agentos_agent_dashboard,
       { controller: 'redmineflux_agentos/agent_dashboards', action: 'index' },
       caption: :label_agentos_agent_dashboard, parent: :agentos, param: :project_id

  menu :project_menu, :agentos_dependency_dashboard,
       { controller: 'redmineflux_agentos/dependency_dashboards', action: 'show' },
       caption: :label_agentos_dependency_dashboard, parent: :agentos, param: :project_id

  menu :project_menu, :agentos_token_usage,
       { controller: 'redmineflux_agentos/token_usages', action: 'show' },
       caption: :label_agentos_token_usage, parent: :agentos, param: :project_id

  menu :project_menu, :agentos_cost_dashboard,
       { controller: 'redmineflux_agentos/cost_dashboards', action: 'show' },
       caption: :label_agentos_cost_dashboard, parent: :agentos, param: :project_id

  menu :project_menu, :agentos_execution_history,
       { controller: 'redmineflux_agentos/execution_histories', action: 'show' },
       caption: :label_agentos_execution_history, parent: :agentos, param: :project_id

  # --- Global "+ New AI Project" entry point (docs/PHASE1-SPECIFICATION.md §4.3) ---
  menu :application_menu, :new_ai_project,
       { controller: 'redmineflux_agentos/new_ai_projects', action: 'new' },
       caption: :label_new_ai_project,
       if: proc { User.current.allowed_to?(:create_ai_project, nil, global: true) }

  # --- Administration menu (docs/PHASE1-SPECIFICATION.md §4.2) ---
  menu :admin_menu, :agentos_admin,
       { controller: 'redmineflux_agentos/admin/settings', action: 'show' },
       caption: :label_agentos, html: { class: 'icon icon-settings' }

  menu :admin_menu, :agentos_admin_agents,
       { controller: 'redmineflux_agentos/admin/agents', action: 'index' },
       caption: :label_agentos_admin_agents, parent: :agentos_admin

  menu :admin_menu, :agentos_admin_prompt_library,
       { controller: 'redmineflux_agentos/admin/prompt_templates', action: 'index' },
       caption: :label_agentos_admin_prompt_library, parent: :agentos_admin

  menu :admin_menu, :agentos_admin_mcp_tools,
       { controller: 'redmineflux_agentos/admin/mcp_tools', action: 'index' },
       caption: :label_agentos_admin_mcp_tools, parent: :agentos_admin

  menu :admin_menu, :agentos_admin_settings,
       { controller: 'redmineflux_agentos/admin/settings', action: 'show' },
       caption: :label_agentos_admin_settings, parent: :agentos_admin

  menu :admin_menu, :agentos_admin_audit_logs,
       { controller: 'redmineflux_agentos/admin/audit_logs', action: 'index' },
       caption: :label_agentos_admin_audit_logs, parent: :agentos_admin
end
