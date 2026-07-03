# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #5.
    class SolutionArchitectAgent < BaseAgent
      def self.key
        :solution_architect
      end

      def self.prompt_category
        'dependency_analysis'
      end
    end
  end
end
