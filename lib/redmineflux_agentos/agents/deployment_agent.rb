# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #14. Final tier in the default dependency chain.
    class DeploymentAgent < BaseAgent
      def self.key
        :deployment
      end

      def self.prompt_category
        'ticket_generation'
      end
    end
  end
end
