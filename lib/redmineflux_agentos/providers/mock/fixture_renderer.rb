# frozen_string_literal: true

module RedminefluxAgentos
  module Providers
    module Mock
      # Interpolates `{{variable}}` placeholders (the same syntax as Prompt
      # Management, docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §6) into a
      # loaded fixture's content, tool_call params, and memory_updates
      # values alike — the whole fixture tree is walked once, uniformly.
      module FixtureRenderer
        VARIABLE_PATTERN = /\{\{\s*(\w+)\s*\}\}/.freeze

        class << self
          # @param fixture [Hash] as loaded by FixtureLoader
          # @param variables [Hash] the request's `variables` (§2.1) —
          #   keys are normalized to strings so callers may pass either
          #   string or symbol keys
          # @return [Hash] the fixture with every `{{variable}}` resolved
          # @raise [RedminefluxAgentos::PromptVariableMissingError] if the
          #   fixture references a variable the caller didn't provide (§8.2,
          #   the `variable_missing` error_code, §2.3)
          def render(fixture, variables)
            normalized = variables.transform_keys(&:to_s)
            deep_render(fixture, normalized)
          end

          private

          def deep_render(value, variables)
            case value
            when String
              render_string(value, variables)
            when Hash
              value.transform_values { |v| deep_render(v, variables) }
            when Array
              value.map { |v| deep_render(v, variables) }
            else
              value
            end
          end

          def render_string(str, variables)
            str.gsub(VARIABLE_PATTERN) do
              var_name = ::Regexp.last_match(1)
              unless variables.key?(var_name)
                raise RedminefluxAgentos::PromptVariableMissingError,
                      "Fixture references {{#{var_name}}}, which was not provided in the request's variables"
              end
              variables[var_name].to_s
            end
          end
        end
      end
    end
  end
end
