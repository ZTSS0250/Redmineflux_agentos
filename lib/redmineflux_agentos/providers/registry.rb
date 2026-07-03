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
        # @return the active provider instance for this project (v1: always
        #   resolves to :mock, per docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md
        #   §12's v1 gate — `active_provider` may not resolve to anything
        #   else until a real provider ships)
        def active(project: nil)
          key = RedminefluxAgentos::Configuration::Store.get('active_provider', project: project).to_s.to_sym
          provider_class = @providers[key]

          unless provider_class
            raise RedminefluxAgentos::Configuration::InvalidProviderError,
                  "active_provider resolved to #{key.inspect}, which is not registered"
          end

          provider_class.new
        end

        def registered?(key)
          @providers.key?(key.to_sym)
        end
      end
    end
  end
end
