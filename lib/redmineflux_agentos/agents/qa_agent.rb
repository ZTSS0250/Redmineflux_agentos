# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #11. Tier 5 in the default dependency chain (parallel with Security Agent).
    class QaAgent < BaseAgent
      def self.key
        :qa
      end

      def self.prompt_category
        'ticket_generation'
      end
    end
  end
end
