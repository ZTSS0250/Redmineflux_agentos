# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #12. Tier 5 in the default dependency chain (parallel with QA Agent).
    class SecurityAgent < BaseAgent
      def self.key
        :security
      end

      def self.prompt_category
        'risk_analysis'
      end
    end
  end
end
