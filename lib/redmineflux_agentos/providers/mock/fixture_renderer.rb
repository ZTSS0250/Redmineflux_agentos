# frozen_string_literal: true

module RedminefluxAgentos
  module Providers
    module Mock
      # Interpolates `{{variable}}` placeholders (the same syntax as Prompt
      # Management, docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §6) into a
      # loaded fixture's content. Phase 12 (rao-017) implements this.
      module FixtureRenderer
        def self.render(fixture, variables)
          raise NotImplementedError, 'Fixture rendering is implemented in Phase 12 (rao-017)'
        end
      end
    end
  end
end
