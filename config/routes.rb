# frozen_string_literal: true

# ---------------------------------------------------------------------------
# redmineflux_agentos routes
# ---------------------------------------------------------------------------
# Project-scoped HTML pages live under /projects/:project_id/agentos/...
# The REST/JSON API (consumed by the shared external Redmineflux MCP server,
# per docs/PHASE1-SPECIFICATION.md §7 Q3) lives under /agentos/... — the two
# are deliberately separate route trees, not aliases of each other.
# No actions beyond routing exist yet — see docs/PHASE5-FOLDER-STRUCTURE.md.
# ---------------------------------------------------------------------------

RedmineApp::Application.routes.draw do
  # Global, project-less entry point — there is no project yet when
  # starting a brand new AI project (docs/UI-WIREFRAMES.md §1), so this is
  # a separate controller, deliberately NOT nested under /projects/:project_id
  # like every other AgentOS route below (which all act on an existing project).
  resource :new_ai_project, only: %i[new create], controller: 'redmineflux_agentos/new_ai_projects'

  scope 'projects/:project_id/agentos', module: 'redmineflux_agentos', as: 'agentos' do
    resource :chat, only: %i[show create]
    resource :requirement_review, only: %i[show update]

    resources :agent_dashboards, only: %i[index show] do
      member do
        post :approve
        post :reject
      end
    end

    resource :dependency_dashboard, only: %i[show]

    resources :releases, only: %i[index show] do
      resources :sprints, only: %i[show]
    end

    resource :token_usage, only: %i[show]
    resource :cost_dashboard, only: %i[show]
    resource :execution_history, only: %i[show]
  end

  namespace :redmineflux_agentos do
    namespace :admin do
      resources :agents, only: %i[index edit update]
      resources :prompt_templates, only: %i[index show edit update]
      resources :mcp_tools, only: %i[index update]
      resource :settings, only: %i[show update]
      resources :audit_logs, only: %i[index show]
    end
  end

  # REST/JSON API — filled in by Phase 13 (MCP Implementation, rao-018).
  # Routed and scoped now so Phase 10's plugin boots with the final shape;
  # no endpoints are declared here until their controllers exist.
  scope '/agentos', defaults: { format: 'json' } do
    # rao-021: deliberately outside every other route's require_login —
    # see HealthController's class comment.
    get 'health', to: 'redmineflux_agentos/health#show'
    get 'metrics', to: 'redmineflux_agentos/health#metrics'
  end
end
