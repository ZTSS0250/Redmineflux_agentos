# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #6. Tier 1 in the default dependency chain.
    class DatabaseAgent < BaseAgent
      def self.key
        :database_agent
      end
    end
  end
end
