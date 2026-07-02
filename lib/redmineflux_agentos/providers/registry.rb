# frozen_string_literal: true

module RedminefluxAgentos
  module Providers
    # Provider::Registry — boot-time registration of every available
    # provider (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §3.1). Populated
    # by config/initializers/redmineflux_agentos.rb's `to_prepare` block.
    # Open/Closed extension point: a new provider is a new `register` call,
    # never a change to this class (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.3).
    module Registry
      @providers = {}

      class << self
        def register(key, provider_class)
          @providers[key.to_sym] = provider_class
        end

        # @param project [Project, nil]
        # @return the active provider instance for this project (v1: always Mock)
        def active(project: nil)
          raise NotImplementedError, 'Provider selection via Configuration::Store is implemented in Phase 12 (rao-017)'
        end

        def registered?(key)
          @providers.key?(key.to_sym)
        end
      end
    end
  end
end
