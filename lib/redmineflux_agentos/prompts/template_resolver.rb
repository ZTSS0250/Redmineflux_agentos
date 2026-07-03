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
    # Scope note: no explicit-invalidation cache (§B.3) yet — every call
    # reads through to the DB. Caching is a pure performance layer on top
    # of already-correct behavior; adding it can't fix a correctness gap,
    # so it's deferred rather than adding complexity this ticket doesn't
    # strictly need to satisfy its own Objectives.
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
          template = active_template(key, agent)
          unless template
            raise RedminefluxAgentos::PromptVariableMissingError,
                  "No active prompt template found for key '#{key}'"
          end

          ensure_required_variables_present!(key, template, variables)
          interpolate(template.content, variables)
        end

        private

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
