# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #13. Tier 6 in the default dependency chain (parallel with Deployment Agent).
    class DevopsAgent < BaseAgent
      def self.key
        :devops
      end
    end
  end
end
