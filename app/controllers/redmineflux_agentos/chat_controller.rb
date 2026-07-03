# frozen_string_literal: true

module RedminefluxAgentos
  # AI Chat for an existing project's conversation (docs/UI-WIREFRAMES.md §1).
  # Starting a brand new project uses NewAiProjectsController instead.
  #
  # Gap acknowledged, not silently worked around (rao-020 Gate 1
  # revision): `create` persists the user's message correctly but does
  # not enqueue an actual agent turn in response. Doing that is
  # `ConversationManager::Session`'s job (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md
  # §A.8 — "delegates each turn to the Requirement Analyzer service,
  # which is what actually calls the Agent Engine") — that class, and the
  # Requirement Analyzer service it would call, do not exist anywhere in
  # this codebase yet, and no ticket from `rao-015` through `rao-021`
  # itemizes them as a deliverable. Building a parallel, ad hoc bridge
  # here (this controller directly enqueuing an `AgentRunJob`) would
  # duplicate logic §A.8 already owns and likely get its contract wrong
  # in a way a real Conversation Architecture ticket would need to
  # rework. This is flagged for a future ticket, not fixed here.
  class ChatController < BaseController
    def show
      @conversation = latest_conversation
      @messages = @conversation ? RedminefluxAgentosMessage.where(conversation_id: @conversation.id).order(:created_at) : []
    end

    def create
      @conversation = latest_conversation || RedminefluxAgentosConversation.create!(
        project_id: @project.id, user_id: User.current.id, status: 'active',
        title: params[:text].to_s.truncate(80)
      )
      RedminefluxAgentosMessage.create!(conversation_id: @conversation.id, role: 'user', content: params[:text])

      head :no_content
    end

    private

    def latest_conversation
      RedminefluxAgentosConversation.where(project_id: @project.id, user_id: User.current.id)
                                     .order(created_at: :desc).first
    end
  end
end
