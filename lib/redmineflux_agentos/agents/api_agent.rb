# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #8. Tier 3 in the default dependency chain.
    class ApiAgent < BaseAgent
      def self.key
        :api
      end

      def self.prompt_category
        'ticket_generation'
      end
    end
  end
end
