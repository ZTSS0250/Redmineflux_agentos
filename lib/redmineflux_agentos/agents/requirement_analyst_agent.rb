# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #2.
    class RequirementAnalystAgent < BaseAgent
      def self.key
        :requirement_analyst
      end

      def self.prompt_category
        'requirement_analysis'
      end
    end
  end
end
