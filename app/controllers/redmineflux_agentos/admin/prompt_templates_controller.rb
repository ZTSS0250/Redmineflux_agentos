# frozen_string_literal: true

module RedminefluxAgentos
  module Admin
    # Prompt Library (docs/PHASE9-UI-UX-SPECIFICATION.md §4.1). The one
    # genuinely real business-logic piece here — not just CRUD — is
    # versioning: a new edit is a new `version` row, activating one
    # deactivates the previously-active row for that `key`, in the same
    # transaction (Phase 4 §11 / Phase 3 §6) — an in-flight `agent_run`
    # that already resolved a template keeps using what it resolved.
    class PromptTemplatesController < BaseController
      def index
        @templates = RedminefluxAgentosPromptTemplate.where(is_active: true).order(:key)
      end

      # `:id` is one specific version row; the page shows every version
      # sharing that row's `key` (docs/PHASE9-UI-UX-SPECIFICATION.md §4.1's
      # "v1 (superseded) v2 (superseded) v3 (active)" wireframe).
      def show
        @template = RedminefluxAgentosPromptTemplate.find(params[:id])
        @versions = RedminefluxAgentosPromptTemplate.where(key: @template.key).order(:version)
      end

      def edit
        @template = RedminefluxAgentosPromptTemplate.find(params[:id])
      end

      def update
        current = RedminefluxAgentosPromptTemplate.find(params[:id])

        if params[:activate_version_id].present?
          activate!(current.key, params[:activate_version_id])
        else
          create_new_draft!(current, params[:content])
        end

        redirect_to admin_prompt_template_path(id: current.id)
      end

      private

      def activate!(key, version_id)
        ActiveRecord::Base.transaction do
          RedminefluxAgentosPromptTemplate.where(key: key, is_active: true).update_all(is_active: false)
          RedminefluxAgentosPromptTemplate.find(version_id).update!(is_active: true)
        end
      end

      def create_new_draft!(current, content)
        next_version = RedminefluxAgentosPromptTemplate.where(key: current.key).maximum(:version).to_i + 1

        ActiveRecord::Base.transaction do
          RedminefluxAgentosPromptTemplate.where(key: current.key, is_active: true).update_all(is_active: false)
          RedminefluxAgentosPromptTemplate.create!(
            key: current.key,
            agent_id: current.agent_id,
            version: next_version,
            content: content,
            variables_json: current.variables_json,
            is_active: true,
            created_by_id: User.current.id
          )
        end
      end
    end
  end
end
