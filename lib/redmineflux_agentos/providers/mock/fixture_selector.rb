# frozen_string_literal: true

module RedminefluxAgentos
  module Providers
    module Mock
      # Resolves a fixture key from (agent_key, prompt_category,
      # scenario_key) — never by hashing/matching free-text input
      # (WORKFLOW.md §18). Round-qualifies the scenario_key where needed
      # (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §7). Falls back to the
      # "unhandled scenario" fixture (§8.5) rather than raising. Phase 12
      # (rao-017) implements the lookup itself.
      module FixtureSelector
        def self.resolve(agent_key:, prompt_category:, scenario_key:, round_number: nil)
          raise NotImplementedError, 'Fixture selection is implemented in Phase 12 (rao-017)'
        end
      end
    end
  end
end
