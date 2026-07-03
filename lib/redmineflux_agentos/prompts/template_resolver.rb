# frozen_string_literal: true

module RedminefluxAgentos
  module Prompts
    # PromptManager::TemplateResolver (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md
    # §A.10) — resolves the single `is_active: true` template row for a key
    # (role-specific if `agent` has one, else the shared/system template),
    # validates required variables before ever reaching the Provider, and
    # composes the final prompt via `{{variable}}` interpolation (the same
    # syntax as Mock Provider fixtures, docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md
    # §6).
    #
    # rao-021 (Phase 16 §B.3): the active template per key is now
    # `Rails.cache`-backed, explicit-invalidation only (never time-based,
    # per docs/PHASE1-SPECIFICATION.md §1.3's NFR). A generation counter
    # per `key` — not a direct cache write from the resolver — is what
    # gets invalidated: `Admin::PromptTemplatesController#activate!` and
    # `#create_new_draft!` both use `update_all` for the deactivation
    # half of their transaction, which skips AR callbacks entirely, so an
    # `after_save` hook on the model would silently miss exactly the write
    # this cache most needs to react to. A generation counter sidesteps
    # that: invalidation is one `Rails.cache.increment`, no enumeration of
    # which agent-scoped cache entries currently exist for `key` required.
    #
    # "No active template found for this key" reuses
    # `PromptVariableMissingError` rather than a new error class — no
    # design doc distinguishes "missing template" from "missing variable"
    # as separate failure categories, and both mean the same thing to a
    # caller: the resolver could not produce a valid prompt.
    module TemplateResolver
      VARIABLE_PATTERN = /\{\{\s*(\w+)\s*\}\}/.freeze

      class << self
        # @param key [String] e.g. "requirement_analysis.parse_idea"
        # @param agent [RedminefluxAgentosAgent, nil] role-specific lookup
        #   when present, else the shared/system template
        # @param variables [Hash] string or symbol keys accepted
        # @return [String] the composed prompt
        def resolve(key, agent: nil, variables: {})
          template = cached_active_template(key, agent)
          unless template
            raise RedminefluxAgentos::PromptVariableMissingError,
                  "No active prompt template found for key '#{key}'"
          end

          ensure_required_variables_present!(key, template, variables)
          interpolate(template.content, variables)
        end

        # Called by `Admin::PromptTemplatesController` after any write
        # that changes which row is active for `key` (activation, or a
        # new draft superseding the previous active version) — both
        # insert and "delete" (deactivate) paths invalidate the same way.
        def invalidate!(key)
          Rails.cache.increment(generation_cache_key(key), 1, initial: 1)
        end

        private

        def cached_active_template(key, agent)
          generation = Rails.cache.fetch(generation_cache_key(key)) { 1 }
          agent_scope = agent&.id || 'shared'
          Rails.cache.fetch("redmineflux_agentos/prompt_template/#{key}/#{agent_scope}/gen#{generation}") do
            active_template(key, agent)
          end
        end

        def generation_cache_key(key)
          "redmineflux_agentos/prompt_template_generation/#{key}"
        end

        def active_template(key, agent)
          scope = RedminefluxAgentosPromptTemplate.where(key: key.to_s, is_active: true)
          role_specific = agent && scope.find_by(agent_id: agent.id)
          role_specific || scope.find_by(agent_id: nil)
        end

        def ensure_required_variables_present!(key, template, variables)
          declared = template.variables_json.present? ? Array(JSON.parse(template.variables_json)) : []
          normalized = variables.transform_keys(&:to_s)
          missing = declared.reject { |v| normalized.key?(v.to_s) }
          return if missing.empty?

          raise RedminefluxAgentos::PromptVariableMissingError,
                "Template '#{key}' missing required variable(s): #{missing.join(', ')}"
        end

        def interpolate(content, variables)
          normalized = variables.transform_keys(&:to_s)
          content.gsub(VARIABLE_PATTERN) { normalized[::Regexp.last_match(1)].to_s }
        end
      end
    end
  end
end
