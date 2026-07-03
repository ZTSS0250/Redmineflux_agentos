# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #6. Tier 1 in the default dependency chain.
    class DatabaseAgent < BaseAgent
      def self.key
        :database_agent
      end

      def self.prompt_category
        'ticket_generation'
      end
    end
  end
end
