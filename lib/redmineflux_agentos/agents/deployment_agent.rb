# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #14. Final tier in the default dependency chain.
    class DeploymentAgent < BaseAgent
      def self.key
        :deployment
      end
    end
  end
end
