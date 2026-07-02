# frozen_string_literal: true

module RedminefluxAgentos
  # AI Chat for an existing project's conversation (docs/UI-WIREFRAMES.md §1).
  # Starting a brand new project uses NewAiProjectsController instead.
  class ChatController < BaseController
    def show
    end

    def create
      head :no_content
    end
  end
end
