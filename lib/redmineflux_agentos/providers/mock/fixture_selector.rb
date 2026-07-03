# frozen_string_literal: true

module RedminefluxAgentos
  module Providers
    module Mock
      # Resolves a fixture key from (agent_key, prompt_category,
      # scenario_key) — never by hashing/matching free-text input
      # (WORKFLOW.md §18). Round-qualifies the scenario_key where needed
      # (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §7). Falls back to the
      # "unhandled scenario" fixture (§8.5) rather than raising — an
      # exception is only raised if even the fallback fixture is missing
      # (§8.1, a genuine misconfiguration, not an ordinary coverage gap).
      module FixtureSelector
        class << self
          # @param agent_key [String, Symbol]
          # @param prompt_category [String, Symbol]
          # @param scenario_key [String, Symbol] which fixture within the
          #   category — most categories have exactly one scenario sharing
          #   the category's own name (the Standard Request Model, §2.1,
          #   has no dedicated field for this; callers with more than one
          #   scenario per category, e.g. Project Planning's create_project
          #   / project_plan / agent_assignment, pass it explicitly)
          # @param round_number [Integer, nil] folded into the scenario_key
          #   for round-qualified categories (Clarification Questions, §7)
          # @return [Hash] the rendered-ready fixture (still unrendered —
          #   FixtureRenderer interpolates it)
          def resolve(agent_key:, prompt_category:, scenario_key:, round_number: nil)
            key = round_number ? "#{scenario_key}_round_#{round_number}" : scenario_key.to_s
            relative_path = File.join(agent_key.to_s, prompt_category.to_s, "#{key}.yml")

            fixture = FixtureLoader.load(relative_path)
            return fixture if fixture

            fallback = FixtureLoader.load(FixtureLoader::FALLBACK_RELATIVE_PATH)
            return fallback if fallback

            raise RedminefluxAgentos::Providers::FixtureNotFoundError,
                  "No fixture at #{relative_path}, and no fallback fixture is configured " \
                  "at #{FixtureLoader::FALLBACK_RELATIVE_PATH}"
          end
        end
      end
    end
  end
end
