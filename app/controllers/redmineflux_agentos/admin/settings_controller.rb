# frozen_string_literal: true

module RedminefluxAgentos
  module Admin
    # Settings / Configuration admin screen (docs/PHASE9-UI-UX-SPECIFICATION.md
    # §4.2). Reads/writes `RedminefluxAgentosConfiguration` exclusively —
    # never Redmine's built-in plugin settings mechanism (init.rb, rao-015
    # Gate 1 finding #3). Every value passes through
    # `Configuration::CredentialMasking` before display — a sensitive key
    # never renders its real value (rao-014 Gate 2 finding #1, `rao-020`
    # Gate 2 finding #1).
    #
    # `update`'s no-op-on-blank rule is the other half of that same
    # requirement: a masked field re-submitted unchanged must never
    # overwrite the real stored value with the literal masked placeholder
    # string — only a genuinely non-blank submission is written.
    #
    # This is an admin (not project-scoped) controller — `@project` is
    # not set by `Admin::BaseController`; scope is an optional
    # `project_id` param instead (the wireframe's "Scope: [Global ▾]"
    # selector), never a route-nested resource.
    class SettingsController < BaseController
      def show
        @scope_project = params[:project_id].present? ? Project.find_by(id: params[:project_id]) : nil
        @rows = RedminefluxAgentos::Configuration::Store::DEFAULTS.keys.map do |key|
          raw_value = RedminefluxAgentos::Configuration::Store.get(key, project: @scope_project)
          {
            key: key,
            sensitive: RedminefluxAgentos::Configuration::CredentialMasking.sensitive?(key),
            display_value: RedminefluxAgentos::Configuration::CredentialMasking.display_value(key, raw_value)
          }
        end
      end

      def update
        key = params[:key]
        unless RedminefluxAgentos::Configuration::Store::DEFAULTS.key?(key)
          raise ActiveRecord::RecordNotFound, "Unknown configuration key: #{key}"
        end

        submitted = params[:value]
        sensitive = RedminefluxAgentos::Configuration::CredentialMasking.sensitive?(key)

        # A masked field left unchanged submits blank — that means "leave
        # it as-is," never "clear it," for a sensitive key specifically.
        unless sensitive && submitted.blank?
          project = params[:project_id].present? ? Project.find_by(id: params[:project_id]) : nil
          row = RedminefluxAgentosConfiguration.find_or_initialize_by(project_id: project&.id, key: key)
          row.value_json = submitted.to_json
          row.updated_by_id = User.current.id
          row.updated_at = Time.now
          row.save!
        end

        redirect_to admin_settings_path(project_id: params[:project_id])
      end
    end
  end
end
