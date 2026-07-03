# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #7. Tier 2 in the default dependency chain.
    class BackendAgent < BaseAgent
      def self.key
        :backend
      end

      def self.prompt_category
        'ticket_generation'
      end
    end
  end
end
