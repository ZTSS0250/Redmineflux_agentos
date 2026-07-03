# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #9. Tier 4 in the default dependency chain (parallel with UI/UX Agent).
    class FrontendAgent < BaseAgent
      def self.key
        :frontend
      end

      def self.prompt_category
        'ticket_generation'
      end
    end
  end
end
