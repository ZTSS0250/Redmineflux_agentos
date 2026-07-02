# frozen_string_literal: true

module RedminefluxAgentos
  module Providers
    module Mock
      # Reads a fixture YAML file from the configured `fixture_directory`
      # (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §12). Must validate the
      # directory exists at boot and log a clear warning if missing, rather
      # than only failing per-request (rao-008 Gate 3 finding #1) — Phase 12
      # (rao-017) implements this.
      module FixtureLoader
        def self.load(path)
          raise NotImplementedError, 'Fixture loading is implemented in Phase 12 (rao-017)'
        end
      end
    end
  end
end
