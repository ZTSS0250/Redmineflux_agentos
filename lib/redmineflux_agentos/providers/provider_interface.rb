# frozen_string_literal: true

module RedminefluxAgentos
  module Providers
    # The contract every provider — Mock today, a real one from v2
    # (docs/PRODUCT-ROADMAP.md) — implements. Nothing above this interface
    # (Conversation Manager, Agent Engine Runner, any UI) may reference a
    # concrete provider class (Dependency Inversion,
    # docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.3). Field shapes are
    # fully specified in docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §2;
    # this is the skeleton — Phase 12 (rao-017) implements it.
    module ProviderInterface
      # @param _request [Hash] Standard Request Model, §2.1
      # @return [Hash] Standard Response Model, §2.2
      def request(_request)
        raise NotImplementedError, "#{self.class.name}#request is implemented in Phase 12 (rao-017)"
      end

      # @return [Hash] Capability Model, §2.4
      def capabilities
        raise NotImplementedError, "#{self.class.name}#capabilities is implemented in Phase 12 (rao-017)"
      end
    end
  end
end
