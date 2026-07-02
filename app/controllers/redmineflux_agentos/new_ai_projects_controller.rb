# frozen_string_literal: true

module RedminefluxAgentos
  # The "+ New AI Project" entry point (docs/UI-WIREFRAMES.md §1,
  # docs/PHASE1-SPECIFICATION.md §4.3) — deliberately not project-scoped,
  # since no project exists until the wizard's flow creates one. Gated
  # against the global form of :create_ai_project, the same check the
  # menu item's own visibility uses (init.rb).
  class NewAiProjectsController < ApplicationController
    before_action :require_login
    before_action :authorize_create_ai_project
    accept_api_auth

    def new
    end

    def create
      head :no_content
    end

    private

    def authorize_create_ai_project
      deny_access unless User.current.allowed_to?(:create_ai_project, nil, global: true)
    end
  end
end
