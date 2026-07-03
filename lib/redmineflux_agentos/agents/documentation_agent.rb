# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #16. Continuous (not tiered) — passive, ticket-close-triggered.
    class DocumentationAgent < BaseAgent
      def self.key
        :documentation
      end

      def self.prompt_category
        'documentation'
      end
    end
  end
end
