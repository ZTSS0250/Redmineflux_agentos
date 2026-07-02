# frozen_string_literal: true

module RedminefluxAgentos
  # Shared base for every project-scoped AgentOS controller. Finds the
  # project from :project_id and lets Redmine's own `authorize` filter gate
  # each action against the permission declarations in init.rb — no
  # AgentOS-specific authorization logic lives here (docs/PHASE7-MCP-ARCHITECTURE.md
  # §3's Permission Model Layer 1 is Redmine's own authorize, unchanged for
  # human-initiated controller actions).
  class BaseController < ApplicationController
    before_action :require_login
    before_action :find_project
    before_action :authorize
    accept_api_auth

    private

    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
end
